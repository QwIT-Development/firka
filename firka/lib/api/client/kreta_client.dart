import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/data/models/generic_cache_model.dart';
import 'package:firka/data/models/timetable_cache_model.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/reauth_cubit.dart';
import 'package:firka/data/models/token_model.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka/data/util.dart';
import 'package:firka/services/active_account_helper.dart';
import 'package:firka/services/watch_sync_helper.dart';
import '../consts.dart';
import '../token_grant.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

const _watchChannel = MethodChannel('app.firka/watch_sync');

const backoffCount = 4;
const backoffMin = 100;
const backoffStep = 500;

class KretaClient {
  Completer<void>? _tokenMutexCompleter;
  TokenModel model;
  Isar isar;
  final ReauthCubit _reauthCubit;

  KretaClient(this.model, this.isar, this._reauthCubit);

  bool get needsReauth => _reauthCubit.state.needsReauth;

  void clearReauthFlag() {
    _reauthCubit.clear();
    debugPrint('[KretaClient] Reauth flag cleared');
  }

  Future<void> _setReauthFlag() async {
    if (needsReauth) return;
    if (Platform.isIOS) {
      try {
        _watchChannel.invokeMethod('notifyReauthRequired');
      } catch (e) {
        debugPrint('[KretaClient] Watch reauth notification skipped: $e');
      }
    }
    _reauthCubit.setNeedsReauth(true);
    debugPrint('[KretaClient] Reauth flag set');
  }

  Future<TokenModel> _refreshModelWithCrossDeviceLease(
    TokenModel sourceToken,
  ) async {
    final studentIdNorm = sourceToken.studentIdNorm;
    String? leaseOperationId;

    try {
      if (Platform.isIOS && studentIdNorm != null) {
        final watchInstalled = await WatchSyncHelper.isWatchAppInstalled();
        if (watchInstalled) {
          final leaseReady = await WatchSyncHelper.waitForWatchRefreshLease(
            studentIdNorm: studentIdNorm,
          );
          if (!leaseReady) {
            throw Exception('watch_refresh_lease_timeout');
          }
          leaseOperationId = await WatchSyncHelper.acquireIPhoneRefreshLease(
            studentIdNorm: studentIdNorm,
          );
          if (leaseOperationId == null) {
            throw Exception('iphone_refresh_lease_acquire_failed');
          }
        }
      }

      final extended = await extendToken(sourceToken);
      return TokenModel.fromResp(extended);
    } finally {
      if (Platform.isIOS && studentIdNorm != null && leaseOperationId != null) {
        await WatchSyncHelper.releaseIPhoneRefreshLease(
          studentIdNorm: studentIdNorm,
          operationId: leaseOperationId,
        );
      }
    }
  }

  Future<void> _syncTokenToAppleTargets(TokenModel token) async {
    if (!Platform.isIOS) return;
    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      return;
    }

    final watchInstalled = await WatchSyncHelper.isWatchAppInstalled();
    if (!watchInstalled) {
      debugPrint(
        '[KretaClient] Skipping Apple token sync because no paired Watch app is installed',
      );
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
        "[Recovery] Existing token is still valid, skipping recovery steps",
      );
      clearReauthFlag();
      return true;
    }

    logger.info("[Recovery] Step 1: Trying local token refresh...");
    try {
      var tokenModel = await _refreshModelWithCrossDeviceLease(model);

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
      logger.warning(
        "[Recovery] Not iOS or not initialized, cannot try iCloud",
      );
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
          "[Recovery] Waiting ${delay}s before attempt ${attempt + 1}...",
        );
        await Future.delayed(Duration(seconds: delay));
      }

      logger.info(
        "[Recovery] iCloud attempt ${attempt + 1}/${retryDelays.length}...",
      );

      final recovered = await WatchSyncHelper.checkAndRecoverFromiCloud(
        isar: isar,
        tokens: initData.tokens,
        client: this,
        allowExpiredAccessToken: true,
      );

      if (recovered) {
        iCloudHasToken = true;
        await _reloadActiveTokenModel(
          preferredStudentIdNorm: model.studentIdNorm,
        );

        final recoveredExpiry = model.expiryDate;
        if (recoveredExpiry != null &&
            recoveredExpiry.isAfter(
              timeNow().add(const Duration(seconds: 60)),
            )) {
          logger.info(
            "[Recovery] Step 2 SUCCESS on attempt ${attempt + 1}: usable iCloud token applied without immediate refresh",
          );
          clearReauthFlag();
          return true;
        }

        logger.info(
          "[Recovery] Found iCloud token close to expiry, trying refresh...",
        );
        try {
          var tokenModel = await _refreshModelWithCrossDeviceLease(model);

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
            "[Recovery] iCloud token refresh failed on attempt ${attempt + 1}: $e",
          );
          iCloudHasToken = true;
        }
      } else {
        logger.info(
          "[Recovery] No fresh token in iCloud on attempt ${attempt + 1}",
        );
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
        "[Proactive] Token expired or expiring soon, starting recovery...",
      );

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
      "[Proactive] Token still valid until ${model.expiryDate}, no refresh needed",
    );
    return true;
  }

  Future<T> _mutexCallback<T>(Future<T> Function() callback) async {
    const maxWaitTime = Duration(seconds: 30);

    if (_tokenMutexCompleter != null) {
      try {
        await _tokenMutexCompleter!.future.timeout(
          maxWaitTime,
          onTimeout: () {
            logger.warning(
              "[Mutex] Timeout waiting for token mutex, forcing release",
            );
            if (_tokenMutexCompleter != null &&
                !_tokenMutexCompleter!.isCompleted) {
              _tokenMutexCompleter!.complete();
            }
          },
        );
      } catch (_) {}
    }

    _tokenMutexCompleter = Completer<void>();
    try {
      return await callback();
    } finally {
      final completer = _tokenMutexCompleter;
      _tokenMutexCompleter = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<Response> _authReq(String method, String url, [Object? data]) async {
    var localToken = await _mutexCallback<String>(() async {
      var now = timeNow();

      if (now.millisecondsSinceEpoch >=
          model.expiryDate!.millisecondsSinceEpoch) {
        logger.info(
          "Token expired at ${model.expiryDate}, starting recovery for user: ${model.studentId}",
        );

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
      "apiKey": "21ff6c25-d1da-4a68-a811-c881a6057463",
    };

    return await dio.get(
      url,
      options: Options(method: method, headers: headers),
      data: data,
    );
  }

  Future<(dynamic, int)> _authJson(
    String method,
    String url, [
    Object? data,
  ]) async {
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
            "API returned ${resp.statusCode} with empty data for: $url - possible stale session",
          );
        }
      }
    } catch (ex) {
      if (ex is Error) {
        logger.shout(
          "Request to url: $url failed",
          ex.toString(),
          ex.stackTrace,
        );
      } else {
        logger.shout("Request to url: $url failed", ex.toString());
      }

      rethrow;
    }

    return (resp.data, resp.statusCode!);
  }

  Future<ApiResponse<List<Lesson>>> _timetableCachingGet(
    DateTime weekday,
    bool forceCache,
  ) async {
    var from = weekday.getMonday();
    return await _cachingGet(
      genCacheKey(from, model.studentIdNorm!),
      KretaEndpoints.getTimeTable(
        model.iss!,
        from,
        from.add(Duration(days: 6)),
      ),
      forceCache,
      0,
      isar.timetableCacheModels,
      (key, resp) => TimetableCacheModel()
        ..cacheKey = key
        ..values = (resp as List<dynamic>)
            .map((item) => jsonEncode(item))
            .toList(),
      (cache) => cache.values
          .map((data) => Lesson.fromJson(jsonDecode(data)))
          .toList(),
    );
  }

  Future<ApiResponse<List<R>>> _genericListedCachingGet<R>(
    CacheId id,
    String url,
    bool forceCache,
    R Function(dynamic) mapResultEntries,
  ) async {
    return await _genericCachingGet(
      id,
      url,
      forceCache,
      (data) => (data as List<dynamic>).map(mapResultEntries).toList(),
    );
  }

  Future<ApiResponse<R>> _genericCachingGet<R>(
    CacheId id,
    String url,
    bool forceCache,
    R Function(dynamic) makeResult,
  ) async {
    return await _cachingGet(
      // it would be *ideal* to use xor and left shift here, however
      // binary operations seem to round the number down to
      // 32 bits for some reason???
      (model.studentIdNorm! + ((id.index + 1) * pow(10, 11))) as Id,
      url,
      forceCache,
      0,
      isar.genericCacheModels,
      (key, resp) => GenericCacheModel()
        ..cacheKey = key
        ..cacheData = jsonEncode(resp),
      (cache) {
        return makeResult(jsonDecode(cache.cacheData!));
      },
    );
  }

  Future<ApiResponse<R>> _cachingGet<T, R>(
    Id cacheKey,
    String url,
    bool forceCache,
    int counter,
    IsarCollection<T> collection,
    T Function(Id, dynamic) makeCache,
    R Function(T) makeResult,
  ) async {
    var cache = await collection.get(cacheKey);

    if (forceCache && cache != null) {
      logger.finest(
        "_cachingGet(forceCache: $forceCache}): decoding cached response for: $url",
      );
      return ApiResponse.cached(makeResult(cache));
    }

    try {
      var (resp, statusCode) = await _authJson("GET", url);

      if (statusCode >= 400 && cache != null) {
        logger.finest("request failed: $statusCode, using cache for: $url");
        return ApiResponse(makeResult(cache), statusCode, null, true);
      }

      var newCache = makeCache(cacheKey, resp);

      await isar.writeTxn(() async {
        collection.put(newCache);
      });

      return ApiResponse(makeResult(newCache), statusCode, null, false);
    } catch (ex) {
      if (_isTokenExpired(ex)) {
        logger.warning("Token expired, setting needsReauth flag");
        await _setReauthFlag();

        return ApiResponse(null, 0, ex, false);
      }

      if (ex is DioException && counter < backoffCount) {
        logger.finest("Retrying: $counter / $backoffCount");
        final backoffDelay = backoffMin + (counter * backoffStep);
        logger.finest("Waiting: $backoffDelay");
        await Future.delayed(Duration(milliseconds: backoffDelay));

        return _cachingGet(
          cacheKey,
          url,
          forceCache,
          counter + 1,
          collection,
          makeCache,
          makeResult,
        );
      }

      if (cache != null) {
        logger.finest("request failed, using cache for: $url");
        return ApiResponse(makeResult(cache), 0, ex, true);
      }

      logger.finest("request failed, no cache for: $url");
      return ApiResponse(null, 0, ex, false);
    }
  }

  ApiResponse<List<ClassGroupSubjectAverage>>? classGroupAveragesCache;

  Future<ApiResponse<List<ClassGroupSubjectAverage>>> getClassGroupAverages(
    ClassGroup classGroup, {
    bool forceCache = true,
  }) async {
    if (classGroup.studyTask == null) {
      String? err = "classGroup.studyTask is null";
      logger.warning(err);
      return ApiResponse([], 0, err, false);
    }
    if (!forceCache) {
      classGroupAveragesCache = null;
    } else if (classGroupAveragesCache != null) {
      return classGroupAveragesCache!;
    }
    var studyTaskUid = classGroup.studyTask!.uid.toString().split(",").first;
    var resp = await _genericListedCachingGet(
      CacheId.getClassGroupAvg,
      KretaEndpoints.getClassGroupAvg(model.iss!, studyTaskUid),
      forceCache,
      (item) => ClassGroupSubjectAverage.fromJson(item),
    );

    if (resp.err == null) {
      classGroupAveragesCache = ApiResponse.cached(resp.response);
    }
    return resp;
  }

  ApiResponse<Student>? studentCache;

  Future<ApiResponse<Student>> getStudent({bool forceCache = true}) async {
    if (!forceCache) {
      studentCache = null;
    } else if (studentCache != null) {
      return studentCache!;
    }

    return await _genericCachingGet(
      CacheId.getStudent,
      KretaEndpoints.getStudentUrl(model.iss!),
      forceCache,
      (cache) => Student.fromJson(cache),
    ).then((resp) {
      if (resp.err == null) {
        studentCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  ApiResponse<List<ClassGroup>>? classGroupCache;

  Future<ApiResponse<List<ClassGroup>>> getClassGroups({
    bool forceCache = true,
  }) async {
    if (!forceCache) {
      classGroupCache = null;
    } else {
      if (classGroupCache != null) return classGroupCache!;
    }

    return await _genericListedCachingGet(
      CacheId.getClassGroup,
      KretaEndpoints.getClassGroups(model.iss!),
      forceCache,
      (item) => ClassGroup.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        classGroupCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  ApiResponse<List<NoticeBoardItem>>? noticeBoardCache;

  Future<ApiResponse<List<NoticeBoardItem>>> getNoticeBoard({
    bool forceCache = true,
  }) async {
    if (!forceCache) {
      noticeBoardCache = null;
    } else if (noticeBoardCache != null) {
      return noticeBoardCache!;
    }

    return await _genericListedCachingGet(
      CacheId.getNoticeBoard,
      KretaEndpoints.getNoticeBoard(model.iss!),
      forceCache,
      (item) => NoticeBoardItem.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        noticeBoardCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  ApiResponse<List<InfoBoardItem>>? infoBoardCache;

  Future<ApiResponse<List<InfoBoardItem>>> getInfoBoard({
    DateTime? from,
    DateTime? to,
    bool forceCache = true,
  }) async {
    if (forceCache && infoBoardCache != null) return infoBoardCache!;

    return await _genericListedCachingGet(
      CacheId.getInfoBoard,
      KretaEndpoints.getInfoBoard(model.iss!, from, to),
      forceCache,
      (item) => InfoBoardItem.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        infoBoardCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  ApiResponse<List<Grade>>? gradeCache;

  Future<ApiResponse<List<Grade>>> getGrades({bool forceCache = true}) async {
    if (!forceCache) {
      gradeCache = null;
    } else if (gradeCache != null) {
      return gradeCache!;
    }

    return await _genericListedCachingGet(
      CacheId.getGrades,
      KretaEndpoints.getGrades(model.iss!),
      forceCache,
      (item) => Grade.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        resp.response!.sort((a, b) => b.recordDate.compareTo(a.recordDate));
        gradeCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  ApiResponse<List<SubjectAverage>>? subjectAverageCache;

  Future<ApiResponse<List<SubjectAverage>>> getSubjectAverage(
    ClassGroup classGroup, {
    bool forceCache = true,
  }) async {
    String? err;
    if (classGroup.studyTask == null) {
      err = "classGroup.studyTask is null";
      logger.warning(err);
      return ApiResponse(
        List<SubjectAverage>.empty(growable: true),
        0,
        err,
        false,
      );
    }
    if (!forceCache) {
      subjectAverageCache = null;
    } else if (subjectAverageCache != null) {
      return subjectAverageCache!;
    }
    var studyTaskUid = classGroup.studyTask!.uid.toString().split(",").first;

    return await _genericListedCachingGet(
      CacheId.getSubjectAvg,
      KretaEndpoints.getSubjectAvg(model.iss!, studyTaskUid),
      forceCache,
      (item) => SubjectAverage.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        subjectAverageCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
  }

  Future<ApiResponse<List<Homework>>> getHomework({
    DateTime? from,
    DateTime? to,
    bool forceCache = true,
  }) async {
    if (from == null && to == null) {
      DateTime now = timeNow();
      DateTime start = now.copyWith(month: 9, day: 1);
      from = now.isBefore(start) ? start.subtract(Duration(days: 365)) : start;
    }
    return await _genericListedCachingGet(
      CacheId.getHomework,
      KretaEndpoints.getHomework(model.iss!, from, to),
      forceCache,
      (item) => Homework.fromJson(item),
    );
  }

  /// Automatically aligns requests to start at Monday and end at Sunday
  Future<ApiResponse<List<Lesson>>> getTimeTable(
    DateTime from,
    DateTime to, {
    bool forceCache = true,
  }) async {
    var lessons = List<Lesson>.empty(growable: true);
    String? err;
    bool cached = true;

    for (
      var i = from.millisecondsSinceEpoch;
      i < to.millisecondsSinceEpoch;
      i += 604800000
    ) {
      var weekday = DateTime.fromMillisecondsSinceEpoch(i);

      var resp = await _timetableCachingGet(weekday, forceCache);
      if (resp.err != null) {
        return resp;
      }

      lessons.addAll(resp.response!);

      if (!resp.cached) cached = false;
    }

    lessons =
        lessons
            .where(
              (lesson) => lesson.start.isAfter(from) && lesson.end.isBefore(to),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    return ApiResponse(lessons, 200, err, cached);
  }

  Future<ApiResponse<List<AllLessons>>> getLessons({
    bool forceCache = true,
  }) async {
    return await _genericListedCachingGet(
      CacheId.getLessons,
      KretaEndpoints.getLessons(model.iss!),
      forceCache,
      (item) => AllLessons.fromJson(item),
    );
  }

  Future<ApiResponse<List<Test>>> getTests({
    DateTime? from,
    DateTime? to,
    bool forceCache = true,
  }) async {
    return await _genericListedCachingGet(
      CacheId.getTests,
      KretaEndpoints.getTests(model.iss!, from, to),
      forceCache,
      (item) => Test.fromJson(item),
    );
  }

  ApiResponse<List<Omission>>? omissionsCache;

  Future<ApiResponse<List<Omission>>> getOmissions({
    bool forceCache = true,
  }) async {
    if (!forceCache) {
      omissionsCache = null;
    } else {
      if (omissionsCache != null) return omissionsCache!;
    }
    return await _genericListedCachingGet(
      CacheId.getOmissions,
      KretaEndpoints.getOmissions(model.iss!),
      forceCache,
      (item) => Omission.fromJson(item),
    ).then((resp) {
      if (resp.err == null) {
        resp.response!.sort((a, b) => a.date.compareTo(b.date));
        omissionsCache = ApiResponse.cached(resp.response);
      }
      return resp;
    });
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
    ex is TokenExpiredException || ex is InvalidGrantException;
