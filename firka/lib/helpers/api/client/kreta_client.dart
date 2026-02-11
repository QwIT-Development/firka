import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firka/helpers/api/model/all_lessons.dart';
import 'package:firka/helpers/api/model/class_group.dart';
import 'package:firka/helpers/api/model/homework.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../../main.dart';
import '../../db/models/token_model.dart';
import '../../db/util.dart';
import '../../debug_helper.dart';
import '../../active_account_helper.dart';
import '../../watch_sync_helper.dart';
import '../consts.dart';
import '../exceptions/token.dart';
import '../model/grade.dart';
import '../model/notice_board.dart';
import '../model/omission.dart';
import '../model/student.dart';
import '../model/test.dart';
import '../token_grant.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

const _watchChannel = MethodChannel('app.firka/watch_sync');

const backoffCount = 4;
const backoffMin = 100;
const backoffStep = 500;

class ApiResponse<T> {
  T? response;
  int statusCode;
  String? err;
  bool cached;

  ApiResponse(
    this.response,
    this.statusCode,
    this.err,
    this.cached,
  );

  @override
  String toString() {
    return "ApiResponse("
        "response: $response, "
        "statusCode: $statusCode, "
        "err: \"$err\", "
        "cached: $cached"
        ")";
  }
}

class KretaClient {
  bool _tokenMutex = false;
  TokenModel model;
  Isar isar;

  static bool needsReauth = false;

  static final ValueNotifier<bool> reauthStateNotifier = ValueNotifier(false);

  static void clearReauthFlag() {
    needsReauth = false;
    reauthStateNotifier.value = false;
    debugPrint('[KretaClient] Reauth flag cleared');
  }

  static Future<void> _setReauthFlag() async {
    if (needsReauth) return;
    needsReauth = true;
    reauthStateNotifier.value = true;
    debugPrint('[KretaClient] Reauth flag set');
  }

  KretaClient(this.model, this.isar);

  Future<void> _syncTokenToAppleTargets(TokenModel token) async {
    if (!Platform.isIOS) return;
    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      return;
    }

    try {
      await WatchSyncHelper.saveTokenToiCloud(token);
    } catch (e) {
      debugPrint('[KretaClient] iCloud token sync skipped: $e');
    }

    try {
      await WatchSyncHelper.sendTokenToWatch();
    } catch (e) {
      debugPrint('[KretaClient] Watch token sync skipped: $e');
    }
  }

  Future<void> _reloadActiveTokenModel({int? preferredStudentIdNorm}) async {
    final allTokens = await isar.tokenModels.where().findAll();
    if (allTokens.isEmpty) return;

    if (initDone) {
      initData.tokens = allTokens;
      final selected = pickActiveToken(
        tokens: allTokens,
        settings: initData.settings,
        preferredStudentIdNorm: preferredStudentIdNorm ?? model.studentIdNorm,
      );
      if (selected != null) {
        model = selected;
      }
      return;
    }

    if (preferredStudentIdNorm != null) {
      for (final token in allTokens) {
        if (token.studentIdNorm == preferredStudentIdNorm) {
          model = token;
          return;
        }
      }
    }

    model = allTokens.first;
  }

  Future<bool> recoverToken() async {
    logger.info("[Recovery] Starting central token recovery...");
    final now = timeNow();
    final localExpiry = model.expiryDate;
    if (localExpiry != null &&
        localExpiry.isAfter(now.add(const Duration(seconds: 60)))) {
      logger.info(
          "[Recovery] Existing token is still valid, skipping recovery steps");
      clearReauthFlag();
      return true;
    }

    logger.info("[Recovery] Step 1: Trying local token refresh...");
    try {
      var extended = await extendToken(model);
      var tokenModel = TokenModel.fromResp(extended);

      await isar.writeTxn(() async {
        await isar.tokenModels.put(tokenModel);
      });

      model = tokenModel;
      await _syncTokenToAppleTargets(model);
      clearReauthFlag();
      logger.info("[Recovery] Step 1 SUCCESS: Local refresh succeeded");
      return true;
    } catch (e) {
      logger.warning("[Recovery] Step 1 FAILED: Local refresh failed: $e");
    }

    if (!Platform.isIOS || !initDone) {
      logger
          .warning("[Recovery] Not iOS or not initialized, cannot try iCloud");
      return false;
    }

    logger.info("[Recovery] Step 2: Trying iCloud recovery with retries...");
    const retryDelays = [0, 5, 10, 5, 10]; // instant, 5s, 10s, 5s, 10s
    bool iCloudHasToken =
        false; // Track if iCloud has any token (to avoid useless retries)

    for (var attempt = 0; attempt < retryDelays.length; attempt++) {
      final delay = retryDelays[attempt];
      if (delay > 0) {
        if (!iCloudHasToken && attempt > 0) {
          logger.info("[Recovery] Skipping retries - iCloud has no token");
          break;
        }
        logger.info(
            "[Recovery] Waiting ${delay}s before attempt ${attempt + 1}...");
        await Future.delayed(Duration(seconds: delay));
      }

      logger.info(
          "[Recovery] iCloud attempt ${attempt + 1}/${retryDelays.length}...");

      final recovered = await WatchSyncHelper.checkAndRecoverFromiCloud(
        isar: isar,
        tokens: initData.tokens,
        client: this,
      );

      if (recovered) {
        iCloudHasToken = true;
        await _reloadActiveTokenModel(
            preferredStudentIdNorm: model.studentIdNorm);

        final recoveredExpiry = model.expiryDate;
        if (recoveredExpiry != null &&
            recoveredExpiry
                .isAfter(timeNow().add(const Duration(seconds: 60)))) {
          logger.info(
              "[Recovery] Step 2 SUCCESS on attempt ${attempt + 1}: usable iCloud token applied without immediate refresh");
          clearReauthFlag();
          return true;
        }

        logger.info(
            "[Recovery] Found iCloud token close to expiry, trying refresh...");
        try {
          var extended = await extendToken(model);
          var tokenModel = TokenModel.fromResp(extended);

          await isar.writeTxn(() async {
            await isar.tokenModels.put(tokenModel);
          });

          model = tokenModel;
          await _syncTokenToAppleTargets(model);
          clearReauthFlag();
          logger.info("[Recovery] Step 2 SUCCESS on attempt ${attempt + 1}");
          return true;
        } catch (e) {
          logger.warning(
              "[Recovery] iCloud token refresh failed on attempt ${attempt + 1}: $e");
          iCloudHasToken = true;
        }
      } else {
        logger.info(
            "[Recovery] No fresh token in iCloud on attempt ${attempt + 1}");
        if (attempt == 0) {
          iCloudHasToken = false;
        }
      }
    }

    logger.warning("[Recovery] All recovery attempts failed");
    return false;
  }

  Future<bool> refreshTokenProactively() async {
    final now = timeNow();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

    if (model.expiryDate == null ||
        model.expiryDate!.isBefore(fiveMinutesFromNow)) {
      logger.info(
          "[Proactive] Token expired or expiring soon, starting recovery...");

      final recovered = await recoverToken();
      if (recovered) {
        return true;
      }

      logger.warning("[Proactive] Token recovery failed");
      await _setReauthFlag();
      if (Platform.isIOS && needsReauth) {
        try {
          _watchChannel.invokeMethod('notifyReauthRequired');
        } catch (e) {
          debugPrint('[KretaClient] Watch reauth notification skipped: $e');
        }
      }
      return false;
    }

    logger.fine(
        "[Proactive] Token still valid until ${model.expiryDate}, no refresh needed");
    return true;
  }

  Future<T> _mutexCallback<T>(Future<T> Function() callback) async {
    const maxWaitTime = Duration(seconds: 30);
    final startTime = DateTime.now();

    while (_tokenMutex) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        logger.warning(
            "[Mutex] Timeout waiting for token mutex, forcing release");
        _tokenMutex = false;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _tokenMutex = true;
    try {
      return await callback();
    } finally {
      _tokenMutex = false;
    }
  }

  Future<Response> _authReq(String method, String url, [Object? data]) async {
    var localToken = await _mutexCallback<String>(() async {
      var now = timeNow();

      if (now.millisecondsSinceEpoch >=
          model.expiryDate!.millisecondsSinceEpoch) {
        logger.info(
            "Token expired at ${model.expiryDate}, starting recovery for user: ${model.studentId}");

        final recovered = await recoverToken();
        if (!recovered) {
          logger.warning("Token recovery failed for user: ${model.studentId}");
          throw TokenExpiredException();
        }
      }

      return model.accessToken!;
    });

    final headers = <String, String>{
      // "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "accept": "*/*",
      "user-agent": Constants.userAgent,
      "authorization": "Bearer $localToken",
      "apiKey": "21ff6c25-d1da-4a68-a811-c881a6057463"
    };

    return await dio.get(url,
        options: Options(method: method, headers: headers), data: data);
  }

  Future<(dynamic, int)> _authJson(String method, String url,
      [Object? data]) async {
    Response<dynamic> resp;

    try {
      logger.finest("Sending authenticated request to: $url");
      resp = await _authReq(method, url, data);
      if (!url.endsWith("TanuloAdatlap")) {
        logger.finest("Response: ${resp.statusCode} ${resp.data}");
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final responseData = resp.data;
        if (responseData == null ||
            (responseData is List && responseData.isEmpty) ||
            (responseData is Map && responseData.isEmpty)) {
          logger.warning(
              "API returned ${resp.statusCode} with empty data for: $url - possible stale session");
        }
      }
    } catch (ex) {
      if (ex is Error) {
        logger.shout(
            "Request to url: $url failed", ex.toString(), ex.stackTrace);
      } else {
        logger.shout("Request to url: $url failed", ex.toString());
      }

      rethrow;
    }

    return (resp.data, resp.statusCode!);
  }

  Future<(dynamic, int, Object?, bool)> _cachingGet(
      CacheId id, String url, bool forceCache, int counter) async {
    // it would be *ideal* to use xor and left shift here, however
    // binary operations seem to round the number down to
    // 32 bits for some reason???
    var cacheKey = model.studentIdNorm! + ((id.index + 1) * pow(10, 11));
    var cache = await isar.genericCacheModels.get(cacheKey as int);

    dynamic resp;
    int statusCode;
    try {
      if (forceCache && cache != null) {
        logger.finest(
            "_cachingGet(forceCache: $forceCache}): decoding cached response for: $url");
        return (jsonDecode(cache.cacheData!), 200, null, true);
      }

      try {
        (resp, statusCode) = await _authJson("GET", url);

        if (statusCode >= 400) {
          if (cache != null) {
            logger.finest(
                "_cachingGet(forceCache: $forceCache}): decoding uncached response for: $url");
            return (jsonDecode(cache.cacheData!), statusCode, null, true);
          }
        }
      } catch (ex) {
        if (ex is Error) {
          logger.finest(
              "Request failed for $url", ex.toString(), ex.stackTrace);
        } else {
          logger.finest("Request failed for $url", ex.toString());
        }
        logger.finest("Retrying: $counter / $backoffCount");
        if (_isTokenExpired(ex) ||
            ex is! DioException ||
            counter >= backoffCount) {
          rethrow;
        }

        final backoffDelay = backoffMin + (counter * backoffStep);
        logger.finest("Waiting: $backoffDelay");
        await Future.delayed(Duration(milliseconds: backoffDelay));

        return _cachingGet(id, url, forceCache, counter + 1);
      }
    } catch (ex) {
      if (_isTokenExpired(ex)) {
        await _setReauthFlag();
        logger.warning("Token expired, setting needsReauth flag");

        if (Platform.isIOS && needsReauth) {
          try {
            _watchChannel.invokeMethod('notifyReauthRequired');
          } catch (e) {
            debugPrint('[KretaClient] Watch reauth notification skipped: $e');
          }
        }
      }

      if (cache != null) {
        logger.finest("request failed, using cache for: $url");
        return (jsonDecode(cache.cacheData!), 0, ex, true);
      } else {
        logger.finest("request failed, no cache for: $url");
        return (null, 0, ex, false);
      }
    }

    await isar.writeTxn(() async {
      var cache = GenericCacheModel();
      cache.cacheKey = cacheKey;
      cache.cacheData = jsonEncode(resp);

      isar.genericCacheModels.put(cache);
    });

    return (resp, statusCode, null, false);
  }

  ApiResponse<Student>? studentCache;

  Future<ApiResponse<Student>> getStudent({bool forceCache = true}) async {
    if (!forceCache) {
      studentCache = null;
    } else if (studentCache != null) {
      return studentCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getStudent,
        KretaEndpoints.getStudentUrl(model.iss!), forceCache, 0);

    Student? student;
    String? err;
    try {
      student = Student.fromJson(resp);
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    if (ex == null) studentCache = ApiResponse(student, 200, null, true);

    return ApiResponse(student, status, err, cached);
  }

  ApiResponse<List<ClassGroup>>? classGroupCache;

  Future<ApiResponse<List<ClassGroup>>> getClassGroups(
      {bool forceCache = true}) async {
    if (!forceCache) {
      classGroupCache = null;
    } else {
      if (classGroupCache != null) return classGroupCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getClassGroup,
        KretaEndpoints.getClassGroups(model.iss!), forceCache, 0);

    final classGroups = List<ClassGroup>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        classGroups.add(ClassGroup.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    if (ex == null) classGroupCache = ApiResponse(classGroups, 200, null, true);

    return ApiResponse(classGroups, status, err, cached);
  }

  ApiResponse<List<NoticeBoardItem>>? noticeBoardCache;

  Future<ApiResponse<List<NoticeBoardItem>>> getNoticeBoard(
      {bool forceCache = true}) async {
    if (!forceCache) {
      noticeBoardCache = null;
    } else if (noticeBoardCache != null) {
      return noticeBoardCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getNoticeBoard,
        KretaEndpoints.getNoticeBoard(model.iss!), forceCache, 0);

    var items = List<NoticeBoardItem>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(NoticeBoardItem.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    if (err == null) noticeBoardCache = ApiResponse(items, 200, null, true);

    return ApiResponse(items, status, err, cached);
  }

  ApiResponse<List<InfoBoardItem>>? infoBoardCache;

  Future<ApiResponse<List<InfoBoardItem>>> getInfoBoard(
      {bool forceCache = true}) async {
    if (forceCache && infoBoardCache != null) return infoBoardCache!;
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getInfoBoard,
        KretaEndpoints.getInfoBoard(model.iss!), forceCache, 0);

    var items = List<InfoBoardItem>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(InfoBoardItem.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    if (err == null) infoBoardCache = ApiResponse(items, 200, null, true);

    return ApiResponse(items, status, err, cached);
  }

  ApiResponse<List<Grade>>? gradeCache;

  Future<ApiResponse<List<Grade>>> getGrades({bool forceCache = true}) async {
    if (!forceCache) {
      gradeCache = null;
    } else if (gradeCache != null) {
      return gradeCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(
        CacheId.getGrades, KretaEndpoints.getGrades(model.iss!), forceCache, 0);

    var items = List<Grade>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(Grade.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    items.sort((a, b) => b.recordDate.compareTo(a.recordDate));

    if (ex == null) gradeCache = ApiResponse(items, 200, null, true);

    return ApiResponse(items, status, err, cached);
  }

  ApiResponse<List<SubjectAverage>>? subjectAverageCache;

  Future<ApiResponse<List<SubjectAverage>>> getSubjectAverage(
      ClassGroup classGroup,
      {bool forceCache = true}) async {
    String? err;
    if (classGroup.studyTask == null) {
      err = "classGroup.studyTask is null";
      logger.warning(err);
      return ApiResponse(
          List<SubjectAverage>.empty(growable: true), 0, err, false);
    }
    if (!forceCache) {
      subjectAverageCache = null;
    } else if (subjectAverageCache != null) {
      return subjectAverageCache!;
    }
    var studyTaskUid = classGroup.studyTask!.uid.toString().split(",").first;
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getSubjectAvg,
        KretaEndpoints.getSubjectAvg(model.iss!, studyTaskUid), forceCache, 0);

    var items = List<SubjectAverage>.empty(growable: true);
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(SubjectAverage.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    if (ex == null) subjectAverageCache = ApiResponse(items, 200, null, true);
    return ApiResponse(items, status, err, cached);
  }

  Future<(List<dynamic>, int, Object?, bool)>
      _timedCachingGet<T extends DatedCacheEntry>(
          IsarCollection<T> cacheModel,
          String endpoint,
          DateTime from,
          DateTime? to,
          bool forceCache,
          int counter,
          Future<void> Function(dynamic, int) storeCache) async {
    var cacheKey = genCacheKey(from, model.studentIdNorm!);
    var cache = await cacheModel.get(cacheKey);
    var formatter = DateFormat('yyyy-MM-dd');
    var fromStr = formatter.format(from);
    var toStr = to != null ? formatter.format(to) : null;
    var now = timeNow();

    if (cache != null && (cache as dynamic).values == null) {
      (cache as dynamic).values = List<String>.empty(growable: true);
    }

    List<dynamic> resp;
    int statusCode;
    try {
      if (forceCache && cache != null) {
        var items = List<dynamic>.empty(growable: true);
        for (var item in (cache as dynamic).values) {
          items.add(jsonDecode(item));
        }

        return (items, 200, null, true);
      }
      try {
        if (toStr == null) {
          (resp, statusCode) = await _authJson(
              "GET",
              "$endpoint?"
                  "datumTol=$fromStr");
        } else {
          (resp, statusCode) = await _authJson(
              "GET",
              "$endpoint?"
                  "datumTol=$fromStr&datumIg=$toStr");
        }

        if (statusCode >= 400) {
          if (cache != null) {
            var items = List<dynamic>.empty(growable: true);
            for (var item in (cache as dynamic).values) {
              items.add(jsonDecode(item));
            }
            return (items, statusCode, null, true);
          }
        }
      } catch (ex) {
        if (_isTokenExpired(ex) ||
            ex is! DioException ||
            counter >= backoffCount) {
          rethrow;
        }

        await Future.delayed(
            Duration(milliseconds: backoffMin + (counter * backoffStep)));

        return _timedCachingGet(cacheModel, endpoint, from, to, forceCache,
            counter + 1, storeCache);
      }
    } catch (ex) {
      if (_isTokenExpired(ex)) {
        await _setReauthFlag();
        logger.warning(
            "Token expired in timed request, setting needsReauth flag");
      }

      if (cache != null) {
        var items = List<dynamic>.empty(growable: true);
        for (var item in (cache as dynamic).values) {
          items.add(jsonDecode(item));
        }
        return (items, 0, ex, true);
      } else {
        return (List<dynamic>.empty(growable: true), 0, ex, false);
      }
    }

    // only cache stuff 4 months ago and a month in advance
    if (from.millisecondsSinceEpoch >=
        now.subtract(Duration(days: 120)).millisecondsSinceEpoch) {
      if (to == null ||
          to.millisecondsSinceEpoch <=
              now.add(Duration(days: 31)).millisecondsSinceEpoch) {
        await isar.writeTxn(() async {
          await storeCache(resp, cacheKey);
        });
      }
    }

    return (resp, statusCode, null, false);
  }

  /// Expects from and to to be 7 days apart
  Future<ApiResponse<List<Lesson>>> _getTimeTable(
      DateTime from, DateTime to, bool forceCache) async {
    var (resp, status, ex, cached) =
        await _timedCachingGet<TimetableCacheModel>(
            isar.timetableCacheModels,
            KretaEndpoints.getTimeTable(model.iss!),
            from,
            to,
            forceCache,
            0, (dynamic resp, int cacheKey) async {
      TimetableCacheModel cache = TimetableCacheModel();
      var rawClasses = List<String>.empty(growable: true);

      for (var obj in resp) {
        rawClasses.add(jsonEncode(obj));
      }

      cache.cacheKey = cacheKey;
      cache.values = rawClasses;

      await isar.timetableCacheModels.put(cache as dynamic);
    });

    var items = List<Lesson>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(Lesson.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    return ApiResponse(items, status, err, cached);
  }

  Future<ApiResponse<List<Homework>>> getHomework(
      {bool forceCache = true}) async {
    final now = timeNow().subtract(Duration(days: 365));
    var formatter = DateFormat('yyyy-MM-dd');
    var start = formatter.format(now);
    var (resp, status, ex, cached) = await _cachingGet(
        CacheId.getHomework,
        "${KretaEndpoints.getHomework(model.iss!)}?datumTol=$start",
        forceCache,
        0);

    var items = List<Homework>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(Homework.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    // items.sort((a, b) => a.date.compareTo(b.date));

    return ApiResponse(items, status, err, cached);
  }

  /// Automatically aligns requests to start at Monday and end at Sunday
  Future<ApiResponse<List<Lesson>>> getTimeTable(DateTime from, DateTime to,
      {bool forceCache = true}) async {
    var lessons = List<Lesson>.empty(growable: true);
    String? err;
    bool cached = true;

    for (var i = from.millisecondsSinceEpoch;
        i < to.millisecondsSinceEpoch;
        i += 604800000) {
      var from = DateTime.fromMillisecondsSinceEpoch(i);
      var start = from.subtract(Duration(days: from.weekday - 1));
      var end = start.add(Duration(days: 6));

      var resp = await _getTimeTable(start, end, forceCache);
      if (resp.err != null) {
        err = resp.err;
        if (!resp.cached) {
          return resp;
        } else {
          lessons.addAll(resp.response!);
        }
      } else {
        lessons.addAll(resp.response!);
      }
      if (!resp.cached) cached = false;
    }

    lessons.sort((a, b) => a.start.compareTo(b.start));
    lessons = lessons
        .where(
            (lesson) => lesson.start.isAfter(from) && lesson.end.isBefore(to))
        .toList();

    return ApiResponse(lessons, 200, err, cached);
  }

  Future<ApiResponse<List<AllLessons>>> getLessons(
      {bool forceCache = true}) async {
    var (resp, status, ex, cached) = await _cachingGet(
      CacheId.getLessons,
      KretaEndpoints.getLessons(model.iss!),
      forceCache,
      0,
    );

    var items = <AllLessons>[];
    String? err;

    try {
      if (resp is List) {
        for (var item in resp) {
          if (item != null && item is Map<String, dynamic>) {
            items.add(AllLessons.fromJson(item));
          } else {
            logger.warning("$item");
          }
        }
      } else {
        err = "${resp.runtimeType}";
      }
    } catch (e, stack) {
      err = e.toString();
      logger.warning(e, stack);
    }

    if (ex != null) {
      err = ex.toString();
    }

    return ApiResponse(items, status, err, cached);
  }

  Future<ApiResponse<List<Test>>> getTests({bool forceCache = true}) async {
    var (resp, status, ex, cached) = await _cachingGet(
        CacheId.getTests, KretaEndpoints.getTests(model.iss!), forceCache, 0);

    var items = List<Test>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(Test.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    // items.sort((a, b) => a.date.compareTo(b.date));

    return ApiResponse(items, status, err, cached);
  }

  ApiResponse<List<Omission>>? omissionsCache;

  Future<ApiResponse<List<Omission>>> getOmissions(
      {bool forceCache = true}) async {
    if (!forceCache) {
      omissionsCache = null;
    } else {
      if (omissionsCache != null) return omissionsCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getOmissions,
        KretaEndpoints.getOmissions(model.iss!), forceCache, 0);

    var items = List<Omission>.empty(growable: true);
    String? err;
    try {
      List<dynamic> rawItems = resp;
      for (var item in rawItems) {
        items.add(Omission.fromJson(item));
      }
    } catch (ex) {
      err = ex.toString();
    }

    if (ex != null) {
      err = ex.toString();
    }

    items.sort((a, b) => a.date.compareTo(b.date));

    if (ex == null) omissionsCache = ApiResponse(items, 200, null, true);

    return ApiResponse(items, status, err, cached);
  }

  void evictMemCache() {
    studentCache = null;
    noticeBoardCache = null;
    gradeCache = null;
    omissionsCache = null;
    classGroupCache = null;
  }
}

bool _isTokenExpired(Object ex) =>
    ex.toString() == TokenExpiredException().toString() ||
    ex.toString() == InvalidGrantException().toString();
