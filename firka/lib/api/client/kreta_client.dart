import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka_common/data/cache_manager.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/core/dev/mock_backend.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/core/debug_helper.dart';
import 'package:firka_common/data/util.dart';
import '../token_grant.dart';

import 'package:flutter/foundation.dart';

const backoffCount = 4;
const backoffMin = 100;
const backoffStep = 500;

class KretaClient {
  Future<TokenModel>? _tokenMutexCompleter;
  final CacheManager cache;
  final ToastCubit _toastCubit = initData.toastCubit;

  // Serializes writes from independent call sites (renewCache,
  // refreshHomeFeed, etc.) so one can't clobber another's fresher data.
  Future<void> _writeQueue = Future.value();

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (ex, st) {
        completer.completeError(ex, st);
      }
    });
    return completer.future;
  }

  KretaClient(TokenModel model) : cache = CacheManager(model);

  bool get needsReauth => _toastCubit.state.type == ActiveToastType.reauth;

  static int lessonStartToMins(LessonCacheModel lesson) {
    return Duration(
      hours: lesson.start.hour,
      minutes: lesson.start.minute,
    ).inMinutes;
  }

  Future<List<LessonCacheModel>> resolveDailyNth(
    List<LessonCacheModel> lessons,
  ) async {
    HashSet<int> lessonsStarts = HashSet();
    lessonsStarts.addAll(
      lessons.where((l) => !l.isEvent()).map(lessonStartToMins),
    );

    List<int> ordered = lessonsStarts.toList()..sort();
    int offset = ordered.indexOf(8 * 60);
    offset = offset == -1 ? 0 : -offset;
    HashMap<int, int> indexed = HashMap.fromEntries(
      ordered.indexed.map((k) => MapEntry(k.$2, k.$1 + 1 + offset)),
    );

    for (LessonCacheModel l in lessons) {
      if (l.isEvent()) {
        continue;
      }

      l.dailyNth ??= indexed[lessonStartToMins(l)];
    }

    return lessons;
  }

  /// Splits [from, to) into the sub-range(s) that don't fall inside
  /// [excludeFrom, excludeTo). Returns [(from, to)] unchanged if there's no
  /// overlap (including when either exclude bound is null).
  static List<(DateTime, DateTime)> _excludingRange(
    DateTime from,
    DateTime to,
    DateTime? excludeFrom,
    DateTime? excludeTo,
  ) {
    if (excludeFrom == null ||
        excludeTo == null ||
        !from.isBefore(excludeTo) ||
        !to.isAfter(excludeFrom)) {
      return [(from, to)];
    }
    final ranges = <(DateTime, DateTime)>[];
    if (from.isBefore(excludeFrom)) ranges.add((from, excludeFrom));
    if (to.isAfter(excludeTo)) ranges.add((excludeTo, to));
    return ranges;
  }

  Future<void> renewTimetable({
    bool wholeYear = false,
    DateTime? skipFrom,
    DateTime? skipTo,
  }) async {
    DateTime now = timeNow();
    DateTime firstDayOfSchool = now.getFirstSchoolDay();
    DateTime firstDayOfNextYear = firstDayOfSchool.copyWith(
      year: firstDayOfSchool.year + 1,
    );
    DateTime? lastDayOfSchool = await cache
        .getEvents()
        .between(
          firstDayOfNextYear.copyWith(month: 6, day: 1),
          firstDayOfNextYear.copyWith(month: 8, day: 1),
        )
        .startProperty()
        .max();

    if (lastDayOfSchool == null ||
        lastDayOfSchool.isBefore(firstDayOfNextYear.copyWith(month: 6))) {
      wholeYear = true;
      lastDayOfSchool = firstDayOfNextYear;
    }

    if (now.isAfter(lastDayOfSchool)) {
      return;
    }

    DateTime from = firstDayOfSchool;
    if (!wholeYear) {
      from =
          (await cache
              .getClassLessons()
              .between(
                firstDayOfSchool,
                timeNow().getMidnight().getMonday().subtract(Duration(days: 7)),
              )
              .startProperty()
              .max()) ??
          firstDayOfSchool;
    }

    DateTime to = lastDayOfSchool;
    if (!wholeYear) {
      to = to.min(timeNow().getMonday().add(Duration(days: 14)));
    }

    DateTime date = from;
    List<Future> requests = [];
    int i = 0;
    int waitAfter = 5;
    while (date.isBefore(to)) {
      DateTime tmpTo = date.add(Duration(days: 14));
      // Chunk boundaries rarely align with skipFrom/skipTo. Trim the
      // overlap instead of skipping only fully-contained chunks.
      for (final (reqFrom, reqTo) in _excludingRange(
        date,
        tmpTo,
        skipFrom,
        skipTo,
      )) {
        requests.add(getLessons(reqFrom, reqTo));
        i++;
      }
      date = tmpTo;

      if (waitAfter == i) {
        await Future.wait(requests);
        requests = [];
        i = 0;
      }
    }
    await Future.wait(requests);
  }

  Future<void> renewMessages() async {
    DateTime from =
        (await isarInit.messageCacheModels
                .where()
                .sortByCreatedAtDesc()
                .findFirst())
            ?.createdAt ??
        timeNow().getFirstSchoolDay();
    await getInfoBoard(from: from);
    await getNoticeBoard(from: from);
  }

  Future<void>? _initInFlight;

  /// Two `init()` calls close together (initialization.dart + a
  /// reInit-triggered renewCache()) used to run fully concurrently and
  /// interleave writes. Coalesce to one in-flight future.
  Future<void> init() {
    final inFlight = _initInFlight;
    if (inFlight != null) return inFlight;
    final future = _initImpl();
    _initInFlight = future;
    // whenComplete() would return an unawaited derived future, so an
    // error here would get reported as unhandled even though real
    // callers already catch it via the returned `future`.
    future.then((_) => _initInFlight = null, onError: (_) => _initInFlight = null);
    return future;
  }

  Future<void> _initImpl() async {
    await getStudent();
    await getClassGroups();
  }

  Future<void>? _renewCacheInFlight;

  /// Multiple call sites trigger renewCache() close together on cold
  /// start; without this a second call re-runs the whole sync concurrently
  /// and can clobber the first's fresher writes.
  Future<void> renewCache({bool reInit = false}) {
    final inFlight = _renewCacheInFlight;
    if (inFlight != null) return inFlight;
    final future = _renewCacheImpl(reInit: reInit);
    _renewCacheInFlight = future;
    // See init()'s comment on why this isn't future.whenComplete(...).
    future.then(
      (_) => _renewCacheInFlight = null,
      onError: (_) => _renewCacheInFlight = null,
    );
    return future;
  }

  Future<void> _renewCacheImpl({bool reInit = false}) async {
    _toastCubit.setActiveToast(.fetching);
    try {
      if (reInit) {
        await init();
      }
      final currentFrom = timeNow().getMonday();
      final currentTo = currentFrom.add(const Duration(days: 14));
      await Future.wait([
        getTests(),
        getHomework(),
        renewMessages(),
        getGrades(),
        getLessons(currentFrom, currentTo),
      ]);
      await renewTimetable(skipFrom: currentFrom, skipTo: currentTo);

      // manual link
      await getOmissions();

      cache.resolveTeachers();
      _toastCubit.setActiveToast(.none);
    } catch (e) {
      if (!isTokenExpired(e)) {
        _toastCubit.setActiveToast(.error, e);
      }
    }
  }

  /// Runs [action] without the fetching toast. Sets the error toast on failure.
  Future<void> pullRefresh(Future Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!isTokenExpired(e)) {
        _toastCubit.setActiveToast(.error, e);
      }
    }
  }

  /// Refetches everything shown on the home feed (not the full school-year cache).
  Future<void> refreshHomeFeed() async {
    await pullRefresh(() async {
      final weekFrom = timeNow().getMonday();
      final weekTo = weekFrom.add(const Duration(days: 7));
      await Future.wait([
        getStudent(),
        getTests(),
        getHomework(),
        renewMessages(),
        getGrades(),
        getLessons(weekFrom, weekTo),
      ]);
      // manual link
      await getOmissions();
      cache.resolveTeachers();
    });
  }

  /// Fetches lessons in 14-day chunks so [from]..[to] stays under the API range limit.
  Future<void> getLessonsCovering(DateTime from, DateTime to) async {
    DateTime date = from;
    final requests = <Future>[];
    while (date.isBefore(to)) {
      final tmpTo = date.add(const Duration(days: 14));
      final end = tmpTo.isAfter(to) ? to : tmpTo;
      requests.add(getLessons(date, end));
      date = tmpTo;
    }
    await Future.wait(requests);
  }

  Future<void> _setReauthFlag() async {
    _toastCubit.setActiveToast(ActiveToastType.reauth);
    debugPrint('[KretaClient] Reauth flag set');
  }

  Future<TokenModel> _refreshModelWithCrossDeviceLease(
    TokenModel sourceToken,
  ) async {
    final extended = await extendToken(sourceToken);
    return TokenModel.fromResp(extended);
  }

  Future<bool> recoverToken() async {
    final now = DateTime.now();
    final localExpiry = cache.token.expiryDate;
    if (localExpiry.isAfter(now.add(const Duration(seconds: 60)))) {
      return true;
    }

    logger.info("[Recovery] Starting central token recovery...");
    logger.info("[Recovery] Step 1: Trying local token refresh...");
    try {
      var tokenModel = await _refreshModelWithCrossDeviceLease(cache.token);

      await isarInit.writeTxn(() async {
        await isarInit.tokenModels.put(tokenModel);
      });

      cache.token = tokenModel;
      logger.info("[Recovery] Step 1 SUCCESS: Local refresh succeeded");
      return true;
    } catch (e) {
      logger.warning("[Recovery] Step 1 FAILED: Local refresh failed: $e");
    }

    logger.warning("[Recovery] All recovery attempts failed");
    await _setReauthFlag();
    return false;
  }

  Future<bool> refreshTokenProactively() async {
    final now = timeNow();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

    if (cache.token.expiryDate.isBefore(fiveMinutesFromNow)) {
      logger.info(
        "[Proactive] Token expired or expiring soon, starting recovery...",
      );

      final recovered = await recoverToken();
      if (recovered) {
        return true;
      }

      logger.warning("[Proactive] Token recovery failed");
      await _setReauthFlag();
      return false;
    }

    logger.fine(
      "[Proactive] Token still valid until ${cache.token.expiryDate}, no refresh needed",
    );
    return true;
  }

  Future<TokenModel> _lockAndRecoverToken() {
    return _tokenMutexCompleter ??= Future(() async {
      final recovered = await recoverToken();
      if (!recovered) {
        logger.warning(
          "Token recovery failed for user: ${cache.token.username}",
        );
        throw TokenExpiredException();
      }
      return cache.token;
    }).whenComplete(() => _tokenMutexCompleter = null);
  }

  Future<Response> _authReq(String method, String url, [Object? data]) async {
    var localToken = (await _lockAndRecoverToken()).accessToken;

    final headers = <String, String>{
      // "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "accept": "*/*",
      "user-agent": initData.userAgent,
      "authorization": "Bearer $localToken",
      "apiKey": "21ff6c25-d1da-4a68-a811-c881a6057463",
    };

    return await dio.get(
      MockBackend.rewrite(url),
      options: Options(
        method: method,
        headers: headers,
        receiveTimeout: Duration(seconds: 20),
      ),
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

      bool isEmpty(dynamic responseData) {
        return responseData == null ||
            (responseData is String && responseData.isEmpty) ||
            (responseData is List && responseData.isEmpty) ||
            (responseData is Map && responseData.isEmpty);
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (isEmpty(resp.data)) {
          logger.warning(
            "API returned ${resp.statusCode} with empty data for: $url - possible stale session",
          );
        }
      } else {
        logger.warning("Invalid response: ${resp.statusCode} ${resp.data}");
        logger.warning("Headers: ${resp.headers}");
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

  Future<List<C>>
  _renewCache<C extends GenericCacheModel<I>, I extends Identifiable>(
    String url,
    C Function() makeCache,
    I Function(Map<String, dynamic>) makeDto, [
    int counter = 0,
  ]) async {
    try {
      var (resp, statusCode) = await _authJson("GET", url);

      var data = resp;
      final caches = <C>[];
      if (data is Map<String, dynamic>) {
        data = [data];
      }
      if (data is List) {
        for (final e in data) {
          if (e is Map<String, dynamic>) {
            late I dto;
            try {
              dto = makeDto(e);
            } catch (ex) {
              logger.shout(
                "failed to make dto for $C",
                ex,
                ex is Error ? ex.stackTrace : null,
              );
              continue;
            }

            try {
              caches.add(
                makeCache()
                  ..createdAt = DateTime.now()
                  ..cacheKey = cache.genCacheKey(dto)
                  ..apply(CacheContext(cache, dto)),
              );
            } catch (ex) {
              logger.shout(
                "failed to make cache $C: ${ex.toString()}",
                ex,
                ex is Error ? ex.stackTrace : null,
              );
              logger.shout("object: $e");
              continue;
            }
          }
        }
      }

      return caches;
    } catch (ex) {
      if (isTokenExpired(ex)) {
        rethrow;
      }

      if ((ex is DioException &&
              ex.type != .connectionTimeout &&
              ex.type != .connectionError) &&
          counter < backoffCount) {
        logger.finest("Retrying: $counter / $backoffCount");
        final backoffDelay = backoffMin + (counter * backoffStep);
        logger.finest("Waiting: $backoffDelay");
        await Future.delayed(Duration(milliseconds: backoffDelay));

        return await _renewCache(url, makeCache, makeDto, counter + 1);
      }

      logger.finest("request failed: $ex, no cache for: $url");
      rethrow;
    }
  }

  /// Upserts [caches]. Deletes stale rows in [staleScope]. Queued behind
  /// [_writeQueue] — see its doc comment.
  Future<List<C>> _save<C extends GenericCacheModel<I>, I extends Identifiable>(
    List<C> caches, [
    QueryBuilder<C, C, QAfterFilterCondition>? staleScope,
  ]) {
    return _enqueueWrite(() => _saveImpl(caches, staleScope));
  }

  Future<List<C>>
  _saveImpl<C extends GenericCacheModel<I>, I extends Identifiable>(
    List<C> caches,
    QueryBuilder<C, C, QAfterFilterCondition>? staleScope,
  ) async {
    isarInit.writeTxnSync(() {
      if (staleScope != null) {
        final freshKeys = caches.map((c) => c.cacheKey).toSet();
        final staleIds = staleScope
            .findAllSync()
            .map((c) => c.cacheKey)
            .where((key) => !freshKeys.contains(key))
            .toList();
        isarInit.collection<C>().deleteAllSync(staleIds);
      }
      isarInit.collection<C>().putAllSync(caches);
    });
    initData.homeRefreshCubit.requestRefresh();
    return caches;
  }

  Future<List<ClassAverageCacheModel>> getClassGroupAverages(
    ClassGroup classGroup,
  ) async {
    var studyTaskUid = classGroup.studyTask!.uid.toString().split(",").first;
    return await _renewCache(
      KretaEndpoints.getClassGroupAvg(cache.token.iss, studyTaskUid),
      ClassAverageCacheModel.new,
      (json) => ClassGroupSubjectAverage.fromJson(json),
    ).then(_save);
  }

  Future<StudentCacheModel> getStudent() async {
    return (await _renewCache<StudentCacheModel, Student>(
      KretaEndpoints.getStudent(cache.token.iss),
      StudentCacheModel.new,
      (cache) => Student.fromJson(cache),
    ).then(_save)).first;
  }

  Future<List<ClassGroupCacheModel>> getClassGroups() async {
    return await _renewCache(
      KretaEndpoints.getClassGroups(cache.token.iss),
      ClassGroupCacheModel.new,
      (item) => ClassGroup.fromJson(item),
    ).then(_save);
  }

  Future<List<MessageCacheModel>> getNoticeBoard({
    DateTime? from,
    DateTime? to,
  }) async {
    return await _renewCache(
      KretaEndpoints.getNoticeBoard(cache.token.iss, from, to),
      MessageCacheModel.new,
      (item) => NoticeBoardItem.fromJson(item) as MessageItem,
    ).then(_save);
  }

  Future<List<MessageCacheModel>> getInfoBoard({
    DateTime? from,
    DateTime? to,
  }) async {
    return await _renewCache(
      KretaEndpoints.getInfoBoard(cache.token.iss, from, to),
      MessageCacheModel.new,
      (json) => InfoBoardItem.fromJson(json) as MessageItem,
    ).then(_save);
  }

  Future<List<GradeCacheModel>> getGrades() async {
    return await _renewCache(
      KretaEndpoints.getGrades(cache.token.iss),
      GradeCacheModel.new,
      (json) => Grade.fromJson(json),
    ).then((caches) => _save(caches, cache.getGrades()));
  }

  Future<List<HomeworkCacheModel>> getHomework({
    DateTime? from,
    DateTime? to,
  }) async {
    if (from == null && to == null) {
      from = timeNow().getFirstSchoolDay();
    }
    return await _renewCache(
      KretaEndpoints.getHomework(cache.token.iss, from, to),
      HomeworkCacheModel.new,
      (item) => Homework.fromJson(item),
    ).then((caches) => _save(caches, cache.getHomeworks()));
  }

  /// Wipes and replaces every cached lesson in [from]..[to], no Uid diffing.
  Future<List<LessonCacheModel>> _replaceTimetableRange(
    DateTime from,
    DateTime to,
    List<LessonCacheModel> caches,
  ) async {
    late int existingCount;
    late int deletedCount;
    isarInit.writeTxnSync(() {
      // NOT between(from, to): it's inclusive of `to`'s whole day, but
      // `to` here is exclusive (matches what was actually fetched) — the
      // inclusive version deleted a day beyond what `caches` covers.
      final scope = cache.getTimeTable().and().startBetween(
        from.getMidnight(),
        to.getMidnight(),
        includeUpper: false,
      );
      existingCount = scope.countSync();
      deletedCount = scope.deleteAllSync();
      isarInit.lessonCacheModels.putAllSync(caches);
    });

    logger.fine(
      "[RenewCache] _replaceTimetableRange $from..$to: "
      "existing=$existingCount deleted=$deletedCount inserting=${caches.length}",
    );
    initData.homeRefreshCubit.requestRefresh();
    return caches;
  }

  /// Automatically aligns requests to start at Monday and end at Sunday.
  /// Queued behind [_writeQueue] so overlapping ranges can't race.
  Future<List<LessonCacheModel>> getLessons(DateTime from, DateTime to) {
    return _enqueueWrite(() => _getLessonsImpl(from, to));
  }

  Future<List<LessonCacheModel>> _getLessonsImpl(
    DateTime from,
    DateTime to,
  ) async {
    assert(from.difference(to).inDays < 30);
    List<LessonCacheModel> caches;
    try {
      caches = await _renewCache(
        KretaEndpoints.getTimeTable(cache.token.iss, from, to),
        LessonCacheModel.new,
        (json) => Lesson.fromJson(json),
      ).then(resolveDailyNth);
    } catch (ex) {
      if (isTokenExpired(ex)) {
        rethrow;
      }
      // fall back to cache instead of losing the range
      logger.warning(
        "[Timetable] failed to refresh $from..$to, falling back to cache: $ex",
      );
      return cache.getTimeTable().and().between(from, to).findAllSync()
        ..sort((a, b) => a.start.compareTo(b.start));
    }

    return (await _replaceTimetableRange(from, to, caches))
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<List<TestCacheModel>> getTests({DateTime? from, DateTime? to}) async {
    return await _renewCache(
      KretaEndpoints.getTests(cache.token.iss, from, to),
      TestCacheModel.new,
      (item) => Test.fromJson(item),
    ).then(
      (caches) => _save(
        caches,
        isarInit.testCacheModels.filter().classGroup(cache.isCurrentClassGroup),
      ),
    );
  }

  Future<List<OmissionCacheModel>> getOmissions() async {
    return (await _renewCache(
        KretaEndpoints.getOmissions(cache.token.iss),
        OmissionCacheModel.new,
        (item) => Omission.fromJson(item),
      ).then(
        (caches) => _save(
          caches,
          isarInit.omissionCacheModels.filter().classGroup(
            cache.isCurrentClassGroup,
          ),
        ),
      ))
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<SubjectCacheModel>> getSubjects() async {
    return await _renewCache(
      KretaEndpoints.getDktSubjects(cache.token.iss),
      SubjectCacheModel.new,
      (item) => DktSubject.fromJson(item),
    ).then(_save);
  }
}

bool isTokenExpired(Object ex) =>
    ex is TokenExpiredException || ex is InvalidGrantException;
