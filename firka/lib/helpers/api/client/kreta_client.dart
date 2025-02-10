import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firka/helpers/api/model/homework.dart';
import 'package:firka/helpers/api/model/timetable.dart';
import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/homework_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../../main.dart';
import '../../db/models/token_model.dart';
import '../../db/util.dart';
import '../../debug_helper.dart';
import '../consts.dart';
import '../model/grade.dart';
import '../model/notice_board.dart';
import '../model/omission.dart';
import '../model/student.dart';
import '../model/test.dart';
import '../token_grant.dart';

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

  KretaClient(this.model, this.isar);

  Future<T> _mutexCallback<T>(Future<T> Function() callback) async {
    while (_tokenMutex) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _tokenMutex = true;
    try {
      return callback();
    } finally {
      _tokenMutex = false;
    }
  }

  Future<Response> _authReq(String method, String url, [Object? data]) async {
    var localToken = await _mutexCallback<String>(() async {
      var now = timeNow();

      if (now.millisecondsSinceEpoch >=
          model.expiryDate!.millisecondsSinceEpoch) {
        var extended = await extendToken(model);
        var tokenModel = TokenModel.fromResp(extended);

        await isar.writeTxn(() async {
          await isar.tokenModels.put(tokenModel);
        });

        model = tokenModel;
      }

      return model.accessToken!;
    });

    final headers = <String, String>{
      // "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "accept": "*/*",
      "user-agent": "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0",
      "authorization": "Bearer $localToken",
      "apiKey": "21ff6c25-d1da-4a68-a811-c881a6057463"
    };

    return await dio.get(url,
        options: Options(method: method, headers: headers), data: data);
  }

  Future<(dynamic, int)> _authJson(String method, String url,
      [Object? data]) async {
    var resp = await _authReq(method, url, data);

    return (resp.data, resp.statusCode!);
  }

  Future<(dynamic, int, Object?, bool)> _cachingGet(
      CacheId id, String url, bool forceCache) async {
    // it would be *ideal* to use xor and left shift here, however
    // binary operations seem to round the number down to
    // 32 bits for some reason???
    var cacheKey = model.studentId! + ((id.index + 1) * pow(10, 11));
    var cache = await isar.genericCacheModels.get(cacheKey as int);

    dynamic resp;
    int statusCode;
    try {
      if (forceCache && cache != null) {
        return (jsonDecode(cache.cacheData!), 200, null, true);
      }
      (resp, statusCode) = await _authJson("GET", url);

      if (statusCode >= 400) {
        if (cache != null) {
          return (jsonDecode(cache.cacheData!), statusCode, null, true);
        }
      }
    } catch (ex) {
      if (cache != null) {
        return (jsonDecode(cache.cacheData!), 0, ex, true);
      } else {
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
    if (forceCache && studentCache != null) return studentCache!;
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getStudent,
        KretaEndpoints.getStudentUrl(model.iss!), forceCache);

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

  ApiResponse<List<NoticeBoardItem>>? noticeBoardCache;

  Future<ApiResponse<List<NoticeBoardItem>>> getNoticeBoard(
      {bool forceCache = true}) async {
    if (forceCache && noticeBoardCache != null) return noticeBoardCache!;
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getNoticeBoard,
        KretaEndpoints.getNoticeBoard(model.iss!), forceCache);

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

  ApiResponse<List<Grade>>? gradeCache;

  Future<ApiResponse<List<Grade>>> getGrades({bool forceCache = true}) async {
    if (forceCache && gradeCache != null) {
      return gradeCache!;
    }
    var (resp, status, ex, cached) = await _cachingGet(
        CacheId.getGrades, KretaEndpoints.getGrades(model.iss!), forceCache);

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

  Future<(List<dynamic>, int, Object?, bool)>
      _timedCachingGet<T extends DatedCacheEntry>(
          IsarCollection<T> cacheModel,
          String endpoint,
          DateTime from,
          DateTime? to,
          bool forceCache,
          Future<void> Function(dynamic, int) storeCache) async {
    var cacheKey = genCacheKey(from, model.studentId!);
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

    // only cache stuff in a 1 month frame
    if (from.millisecondsSinceEpoch >=
        now.subtract(Duration(days: 30)).millisecondsSinceEpoch) {
      if (to == null ||
          to.millisecondsSinceEpoch <=
              now.add(Duration(days: 30)).millisecondsSinceEpoch) {
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
            forceCache, (dynamic resp, int cacheKey) async {
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

  /// Expects from and to to be 7 days apart
  Future<ApiResponse<List<Homework>>> _getHomework(
      DateTime from, DateTime to, bool forceCache) async {
    var (resp, status, ex, cached) = await _timedCachingGet<HomeworkCacheModel>(
        isar.homeworkCacheModels,
        KretaEndpoints.getHomework(model.iss!),
        from,
        null,
        forceCache, (dynamic resp, int cacheKey) async {
      HomeworkCacheModel cache = HomeworkCacheModel();
      var rawClasses = List<String>.empty(growable: true);

      for (var obj in resp) {
        rawClasses.add(jsonEncode(obj));
      }

      cache.cacheKey = cacheKey;
      cache.values = rawClasses;

      await isar.homeworkCacheModels.put(cache as dynamic);
    });

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

    return ApiResponse(items, status, err, cached);
  }

  /// Automatically aligns requests to start at Monday and end at Sunday
  Future<ApiResponse<List<Homework>>> getHomework(DateTime from, DateTime to,
      {bool forceCache = true}) async {
    var homework = List<Homework>.empty(growable: true);
    String? err;
    bool cached = true;

    for (var i = from.millisecondsSinceEpoch;
        i < to.millisecondsSinceEpoch;
        i += 604800000) {
      var from = DateTime.fromMillisecondsSinceEpoch(i);
      var start = from.subtract(Duration(days: from.weekday - 1));
      var end = start.add(Duration(days: 6));

      var resp = await _getHomework(start, end, forceCache);
      if (resp.err != null) {
        err = resp.err;
        if (!resp.cached) {
          return resp;
        } else {
          homework.addAll(resp.response!);
        }
      } else {
        homework.addAll(resp.response!);
      }
      if (!resp.cached) cached = false;
    }

    homework.sort((a, b) => a.startDate.compareTo(b.startDate));
    homework = homework.where((h) => h.dueDate.isAfter(timeNow())).toList();

    return ApiResponse(homework, 200, err, cached);
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

  Future<ApiResponse<List<Test>>> getTests({bool forceCache = true}) async {
    var (resp, status, ex, cached) = await _cachingGet(
        CacheId.getTests, KretaEndpoints.getTests(model.iss!), forceCache);

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
    if (omissionsCache != null) return omissionsCache!;
    var (resp, status, ex, cached) = await _cachingGet(CacheId.getOmissions,
        KretaEndpoints.getOmissions(model.iss!), forceCache);

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
  }
}
