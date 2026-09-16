// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka_common/data/cache_manager.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:logging/logging.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

const _mockServerUrl = 'http://127.0.0.1:8090';

class _RealHttpOverrides extends HttpOverrides {}

class MockNotificationsPlatform extends FlutterLocalNotificationsPlatform
    with MockPlatformInterfaceMixin {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

Future<TokenGrantResponse> _authenticateMockServer(
  HttpClient httpClient,
) async {
  final loginReq = await httpClient.getUrl(
    Uri.parse('$_mockServerUrl/Account/Login'),
  );
  final loginResp = await loginReq.close();
  final loginBody = await loginResp.transform(utf8.decoder).join();

  final match = RegExp(r'name="code" value="([^"]+)"').firstMatch(loginBody);
  if (match == null) {
    throw Exception(
      'Failed to extract code from mock server login: $loginBody',
    );
  }
  final code = match.group(1)!;

  final tokenReq = await httpClient.postUrl(
    Uri.parse('$_mockServerUrl/connect/token'),
  );
  tokenReq.headers.contentType = ContentType(
    'application',
    'x-www-form-urlencoded',
  );
  tokenReq.write(
    'grant_type=authorization_code&code=${Uri.encodeQueryComponent(code)}',
  );
  final tokenResp = await tokenReq.close();
  final tokenBody = await tokenResp.transform(utf8.decoder).join();
  if (tokenResp.statusCode != 200) {
    throw Exception(
      'Token request failed (${tokenResp.statusCode}): $tokenBody',
    );
  }
  return TokenGrantResponse.fromJson(
    jsonDecode(tokenBody) as Map<String, dynamic>,
  );
}

Future<void> _resetMockServer(HttpClient httpClient) async {
  final req = await httpClient.postUrl(
    Uri.parse('$_mockServerUrl/admin/api/reset'),
  );
  final resp = await req.close();
  await resp.drain();
}

/// The [from, to) ranges of every OrarendElemek (timetable) request the mock
/// server has received since the last reset, in `yyyy-MM-dd` form.
Future<List<(DateTime, DateTime)>> _timetableRequestRanges(
  HttpClient httpClient,
) async {
  final req = await httpClient.getUrl(
    Uri.parse('$_mockServerUrl/admin/api/timetable-requests'),
  );
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final list = jsonDecode(body) as List;
  return list
      .map(
        (e) => (
          DateTime.parse((e as Map<String, dynamic>)['from'] as String),
          DateTime.parse(e['to'] as String),
        ),
      )
      .toList();
}

Future<void> _putTimetable(
  HttpClient httpClient,
  List<Map<String, dynamic>> lessons,
) async {
  final req = await httpClient.putUrl(
    Uri.parse('$_mockServerUrl/admin/api/timetable'),
  );
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(lessons));
  final resp = await req.close();
  if (resp.statusCode != 204 && resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to PUT timetable (${resp.statusCode}): $body');
  }
}

Map<String, dynamic> _lesson({
  required String uid,
  required String start,
  required String end,
  required String name,
  String room = '101',
  String stateUid = '1',
  String stateName = 'Megtartott',
  String stateDesc = 'Megtartott óra',
  String teacher = 'Teszt Tanár',
  String? substituteTeacher,
  int daysFromToday = 0,
}) {
  final today = DateTime.now().add(Duration(days: daysFromToday));
  final datePrefix =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return {
    'Uid': uid,
    'Datum': '${datePrefix}T00:00:00',
    'KezdetIdopont': '${datePrefix}T$start:00',
    'VegIdopont': '${datePrefix}T$end:00',
    'Nev': name,
    'OsztalyCsoport': {'Uid': '10,11.A', 'Nev': '11.A'},
    'TanarNeve': teacher,
    'HelyettesTanarNeve': substituteTeacher,
    'Tantargy': {
      'Uid': '1,MATEK',
      'Nev': name,
      'Kategoria': {
        'Uid': '1',
        'Nev': 'Kötelező',
        'Leiras': 'Kötelező tantárgy',
      },
      'SortIndex': 1,
    },
    'TeremNeve': room,
    'Tipus': {'Uid': '1', 'Nev': 'Tanóra', 'Leiras': 'Tanóra'},
    'TanuloJelenlet': {'Uid': '', 'Nev': '', 'Leiras': ''},
    'Allapot': {'Uid': stateUid, 'Nev': stateName, 'Leiras': stateDesc},
    'IsTanuloHaziFeladatEnabled': false,
    'IsHaziFeladatMegoldva': false,
    'Csatolmanyok': [],
    'IsDigitalisOra': false,
    'DigitalisTamogatoEszkozTipusList': [],
    'Letrehozas': '${datePrefix}T00:00:00',
    'UtolsoModositas': DateTime.now().toUtc().toIso8601String(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterLocalNotificationsPlatform.instance = MockNotificationsPlatform();
  logger = Logger('TimetableCacheReconciliationTest');

  group('Timetable cache reconciliation against mock Kreta server', () {
    late HttpClient httpClient;

    setUp(() {
      HttpOverrides.global = _RealHttpOverrides();
      httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 5);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async => Directory.systemTemp.path,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            (MethodCall methodCall) async => {
              'appName': 'firka',
              'packageName': 'app.firka.naplo',
              'version': '1.0.0',
              'buildNumber': '1',
            },
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('firka.app/main'),
            (MethodCall methodCall) async => 'SM-A705FN;11;30',
          );
    });

    tearDown(() {
      httpClient.close(force: true);
    });

    testWidgets(
      'stale lesson rows are removed when the school edits the timetable',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          await _resetMockServer(httpClient);
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
            _lesson(uid: '9002', start: '08:25', end: '09:10', name: 'Fizika'),
            _lesson(uid: '9003', start: '09:20', end: '10:05', name: 'Kémia'),
          ]);

          final isar = await initDB();
          await isar.writeTxn(() async {
            await isar.clear();
          });
          Settings = SettingsRepository(isar);
          await Settings.loadAll();

          await Settings.mockBackendEnabled.set(true);
          await Settings.mockBackendUrl.set(_mockServerUrl);

          final tokenResp = await _authenticateMockServer(httpClient);
          final tokenModel = TokenModel.fromResp(tokenResp);

          await isar.writeTxn(() async {
            await isar.tokenModels.clear();
            await isar.tokenModels.put(tokenModel);
          });

          await initializeApp();
          expect(initDone, isTrue);

          final client = initData.client!;
          await client.init();
          await client.renewCache(reInit: false);

          final today = DateTime.now();
          bool isToday(DateTime d) =>
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
          List<LessonCacheModel> lessonsFor(CacheManager cache) => cache
              .getTimeTable()
              .findAllSync()
              .where((l) => isToday(l.start))
              .toList();

          final before = lessonsFor(client.cache);
          expect(
            before.length,
            3,
            reason: 'initial sync should cache exactly the 3 seeded lessons',
          );

          // simulates a school schedule edit
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
            _lesson(
              uid: '9002-v2',
              start: '08:20',
              end: '09:00',
              name: 'Fizika',
            ),
            _lesson(uid: '9003', start: '09:05', end: '09:50', name: 'Kémia'),
          ]);

          await client.renewCache(reInit: false);

          final after = lessonsFor(client.cache);
          expect(
            after.length,
            3,
            reason:
                'stale lesson row for the old timetable version should have been deleted',
          );
          expect(
            after.map((l) => l.dailyNth).toSet().length,
            after.length,
            reason: 'no two lessons should occupy the same period number',
          );
        });
      },
    );

    Future<KretaClient> _initAndSync(
      HttpClient httpClient,
      List<Map<String, dynamic>> seedLessons,
    ) async {
      await _resetMockServer(httpClient);
      await _putTimetable(httpClient, seedLessons);

      final isar = await initDB();
      await isar.writeTxn(() async {
        await isar.clear();
      });
      Settings = SettingsRepository(isar);
      await Settings.loadAll();

      await Settings.mockBackendEnabled.set(true);
      await Settings.mockBackendUrl.set(_mockServerUrl);

      final tokenResp = await _authenticateMockServer(httpClient);
      final tokenModel = TokenModel.fromResp(tokenResp);

      await isar.writeTxn(() async {
        await isar.tokenModels.clear();
        await isar.tokenModels.put(tokenModel);
      });

      await initializeApp();
      expect(initDone, isTrue);

      final client = initData.client!;
      await client.init();
      await client.renewCache(reInit: false);
      return client;
    }

    List<LessonCacheModel> _lessonsToday(CacheManager cache) {
      final today = DateTime.now();
      bool isToday(DateTime d) =>
          d.year == today.year && d.month == today.month && d.day == today.day;
      return cache
          .getTimeTable()
          .findAllSync()
          .where((l) => isToday(l.start))
          .toList();
    }

    testWidgets(
      'a room-only substitution that mints a new Uid still leaves exactly one row',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              room: '101',
            ),
          ]);

          expect(_lessonsToday(client.cache).length, 1);

          // room change, new Uid, old Uid gone from this fetch
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9001-v2',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              room: '204',
            ),
          ]);
          await client.renewCache(reInit: false);

          final after = _lessonsToday(client.cache);
          expect(
            after.length,
            1,
            reason:
                'a clean Uid cutover must replace the row, not leave both cached',
          );
          expect(after.single.roomName, '204');
        });
      },
    );

    testWidgets(
      'a cancellation that mints a new Uid still leaves exactly one row',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
          ]);

          expect(_lessonsToday(client.cache).length, 1);

          // cancellation, new Uid, old Uid gone from this fetch
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9001-v2',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              stateUid: '3',
              stateName: 'Elmaradt',
              stateDesc: 'Elmaradt óra',
            ),
          ]);
          await client.renewCache(reInit: false);

          final after = _lessonsToday(client.cache);
          expect(
            after.length,
            1,
            reason:
                'a clean Uid cutover must replace the row, not leave both cached',
          );
          expect(after.single.state, 'Elmaradt');
        });
      },
    );

    testWidgets(
      'a cancellation Uid-swap seen by two overlapping fetches still leaves one row',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
          ]);

          expect(_lessonsToday(client.cache).length, 1);

          // simulates two overlapping fetch windows seeing a Uid swap
          final today = DateTime.now();
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9001-cancelled',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              stateUid: '3',
              stateName: 'Elmaradt',
              stateDesc: 'Elmaradt óra',
            ),
          ]);
          await client.getLessons(
            today.subtract(const Duration(days: 3)),
            today.add(const Duration(days: 4)),
          );

          final after = _lessonsToday(client.cache);
          expect(
            after.length,
            1,
            reason:
                'a cancellation for an existing period should replace the row, '
                'not leave the pre-cancellation copy cached alongside it',
          );
          expect(after.single.state, 'Elmaradt');
        });
      },
    );

    testWidgets(
      'a full-day reschedule swaps every Uid without leaving any stale rows behind',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
            _lesson(uid: '9002', start: '08:25', end: '09:10', name: 'Fizika'),
            _lesson(uid: '9003', start: '09:20', end: '10:05', name: 'Kémia'),
          ]);

          expect(_lessonsToday(client.cache).length, 3);

          // the whole day gets re-issued with brand new Uids (e.g. timetable regenerated)
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9101',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
            _lesson(uid: '9102', start: '08:25', end: '09:10', name: 'Fizika'),
            _lesson(uid: '9103', start: '09:20', end: '10:05', name: 'Kémia'),
          ]);
          await client.renewCache(reInit: false);

          final after = _lessonsToday(client.cache);
          expect(
            after.length,
            3,
            reason:
                'none of the old-Uid rows should survive a full-day reschedule',
          );
          expect(
            after.map((l) => l.cacheKey).toSet().length,
            3,
            reason: 'all surviving rows must belong to the new Uids',
          );
        });
      },
    );

    testWidgets(
      'a substitution Uid-swap seen by two overlapping fetches still leaves one row',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9002',
              start: '08:25',
              end: '09:10',
              name: 'Munkav. idegennyelv',
              teacher: 'Eredeti Tanár',
            ),
          ]);

          expect(_lessonsToday(client.cache).length, 1);

          // reproduces the screenshot bug: two overlapping fetches see a Uid swap
          final today = DateTime.now();
          await _putTimetable(httpClient, [
            _lesson(
              uid: '9002-subst',
              start: '08:25',
              end: '09:10',
              name: 'Munkav. idegennyelv',
              teacher: 'Helyettesítő Tanár',
              substituteTeacher: 'Helyettesítő Tanár',
            ),
          ]);
          await client.getLessons(
            today.subtract(const Duration(days: 3)),
            today.add(const Duration(days: 4)),
          );

          final after = _lessonsToday(client.cache);
          expect(
            after.length,
            1,
            reason:
                'a substitution for an existing period should replace it, not '
                'leave both the pre- and post-substitution rows cached',
          );
          expect(after.single.teacher, 'Helyettesítő Tanár');
        });
      },
    );

    testWidgets(
      'a failed refetch falls back to the existing cache instead of losing it',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          final client = await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
          ]);

          expect(_lessonsToday(client.cache).length, 1);

          // backend isn't listening, so the refetch fails
          await Settings.mockBackendUrl.set('http://127.0.0.1:1');
          final today = DateTime.now();
          final result = await client.getLessons(
            today.subtract(const Duration(days: 1)),
            today.add(const Duration(days: 1)),
          );

          expect(
            result.length,
            1,
            reason: 'a failed request should fall back to the cached lessons',
          );
          expect(
            _lessonsToday(client.cache).length,
            1,
            reason: 'the existing cache must not be wiped by a failed fetch',
          );
        });
      },
    );

    testWidgets(
      'renewCache never issues two overlapping timetable range requests',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          // renewTimetable's chunks are anchored to Sept 1st, which rarely
          // aligns with the current-window's Monday anchor, so chunks used
          // to redundantly re-request an already-fresh range.
          await _initAndSync(httpClient, [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
          ]);

          final ranges = await _timetableRequestRanges(httpClient);
          expect(
            ranges.length,
            greaterThan(1),
            reason:
                'renewCache should fetch more than just the current window '
                '(sanity check that renewTimetable actually ran)',
          );

          for (var i = 0; i < ranges.length; i++) {
            for (var j = i + 1; j < ranges.length; j++) {
              final (aFrom, aTo) = ranges[i];
              final (bFrom, bTo) = ranges[j];
              final overlaps = aFrom.isBefore(bTo) && bFrom.isBefore(aTo);
              expect(
                overlaps,
                isFalse,
                reason:
                    'requests $i ($aFrom..$aTo) and $j ($bFrom..$bTo) overlap: '
                    'a redundant fetch can clobber already-fresh data for '
                    'the days in the overlap',
              );
            }
          }
        });
      },
    );

    testWidgets(
      'a manual full-range refresh overlapping an in-progress chunked sync '
      'never loses a day that was already fetched',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          // Two overlapping, differently-boundaried getLessonsCovering()
          // calls (e.g. two refreshes landing close together) shouldn't
          // wipe an already-cached day via their scoped deletes.
          await _resetMockServer(httpClient);
          await _putTimetable(httpClient, [
            _lesson(
              uid: 'd0',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              daysFromToday: 0,
            ),
            _lesson(
              uid: 'd10',
              start: '07:30',
              end: '08:15',
              name: 'Fizika',
              daysFromToday: 10,
            ),
            _lesson(
              uid: 'd20',
              start: '07:30',
              end: '08:15',
              name: 'Kémia',
              daysFromToday: 20,
            ),
          ]);

          final isar = await initDB();
          await isar.writeTxn(() async {
            await isar.clear();
          });
          Settings = SettingsRepository(isar);
          await Settings.loadAll();

          await Settings.mockBackendEnabled.set(true);
          await Settings.mockBackendUrl.set(_mockServerUrl);

          final tokenResp = await _authenticateMockServer(httpClient);
          final tokenModel = TokenModel.fromResp(tokenResp);

          await isar.writeTxn(() async {
            await isar.tokenModels.clear();
            await isar.tokenModels.put(tokenModel);
          });

          await initializeApp();
          expect(initDone, isTrue);

          final client = initData.client!;
          await client.init();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          bool isOnDay(DateTime d, int offset) {
            final target = today.add(Duration(days: offset));
            return d.year == target.year &&
                d.month == target.month &&
                d.day == target.day;
          }

          int lessonsOn(int offset) => client.cache
              .getTimeTable()
              .findAllSync()
              .where((l) => isOnDay(l.start, offset))
              .length;

          // Sync everything first so all 3 days are already cached.
          await client.getLessonsCovering(
            today,
            today.add(const Duration(days: 23)),
          );
          expect(lessonsOn(0), 1);
          expect(lessonsOn(10), 1);
          expect(lessonsOn(20), 1);

          // Poll during the overlapping re-fetches to catch a transient
          // dip, not just the end state.
          var polling = true;
          var day10DroppedToZero = false;
          var day20DroppedToZero = false;
          unawaited(() async {
            while (polling) {
              if (lessonsOn(10) == 0) day10DroppedToZero = true;
              if (lessonsOn(20) == 0) day20DroppedToZero = true;
              await Future.delayed(Duration.zero);
            }
          }());

          // Two shifted, overlapping ranges fired concurrently.
          await Future.wait([
            client.getLessonsCovering(
              today,
              today.add(const Duration(days: 20)),
            ),
            client.getLessonsCovering(
              today.add(const Duration(days: 3)),
              today.add(const Duration(days: 23)),
            ),
          ]);
          polling = false;

          expect(
            day10DroppedToZero,
            isFalse,
            reason:
                'day 10 was already cached and should never transiently '
                'read as empty during the overlapping re-fetch',
          );
          expect(
            day20DroppedToZero,
            isFalse,
            reason:
                'day 20 was already cached and should never transiently '
                'read as empty during the overlapping re-fetch',
          );

          expect(
            lessonsOn(0),
            1,
            reason: 'day 0 lesson should survive both overlapping fetches',
          );
          expect(
            lessonsOn(10),
            1,
            reason: 'day 10 lesson should survive both overlapping fetches',
          );
          expect(
            lessonsOn(20),
            1,
            reason: 'day 20 lesson should survive both overlapping fetches',
          );
        });
      },
    );

    testWidgets(
      "a chunk's own boundary day survives being fetched by a narrower, "
      'earlier-ending request first',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          // `to` is meant as exclusive everywhere in kreta_client.dart, but
          // the delete scope used to treat it as inclusive, wiping one day
          // beyond what was actually fetched.
          await _resetMockServer(httpClient);
          await _putTimetable(httpClient, [
            _lesson(
              uid: 'boundary',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
              daysFromToday: 3,
            ),
          ]);

          final isar = await initDB();
          await isar.writeTxn(() async {
            await isar.clear();
          });
          Settings = SettingsRepository(isar);
          await Settings.loadAll();
          await Settings.mockBackendEnabled.set(true);
          await Settings.mockBackendUrl.set(_mockServerUrl);

          final tokenResp = await _authenticateMockServer(httpClient);
          final tokenModel = TokenModel.fromResp(tokenResp);
          await isar.writeTxn(() async {
            await isar.tokenModels.clear();
            await isar.tokenModels.put(tokenModel);
          });

          await initializeApp();
          expect(initDone, isTrue);

          final client = initData.client!;
          await client.init();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final boundary = today.add(const Duration(days: 3));

          int lessonsOnBoundaryDay() => client.cache
              .getTimeTable()
              .findAllSync()
              .where(
                (l) =>
                    l.start.year == boundary.year &&
                    l.start.month == boundary.month &&
                    l.start.day == boundary.day,
              )
              .length;

          await client.getLessons(
            today,
            today.add(const Duration(days: 7)),
          );
          expect(lessonsOnBoundaryDay(), 1);

          // `to` lands exactly on the boundary day (exclusive) — must not
          // touch that day's already-cached lesson.
          await client.getLessons(today, boundary);

          expect(
            lessonsOnBoundaryDay(),
            1,
            reason:
                "a fetch whose exclusive `to` is the boundary day must not "
                'delete that day\'s already-cached lessons — it never '
                'asked the server for that day in the first place',
          );
        });
      },
    );

    testWidgets(
      'two occurrences of the same recurring weekly slot on different '
      'dates both survive being cached',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          // Comma-prefixed Uids share a leading "recurring slot" segment
          // across weeks — cacheKey used to be derived from only that
          // segment, so different weeks' lessons overwrote each other.
          await _resetMockServer(httpClient);
          await _putTimetable(httpClient, [
            _lesson(
              uid: '53721555,slotA-week1',
              start: '11:00',
              end: '11:45',
              name: 'Adatbázis-kezelés II',
              daysFromToday: 0,
            ),
            _lesson(
              uid: '53721555,slotA-week2',
              start: '11:00',
              end: '11:45',
              name: 'Adatbázis-kezelés II',
              daysFromToday: 7,
            ),
          ]);

          final isar = await initDB();
          await isar.writeTxn(() async {
            await isar.clear();
          });
          Settings = SettingsRepository(isar);
          await Settings.loadAll();
          await Settings.mockBackendEnabled.set(true);
          await Settings.mockBackendUrl.set(_mockServerUrl);

          final tokenResp = await _authenticateMockServer(httpClient);
          final tokenModel = TokenModel.fromResp(tokenResp);
          await isar.writeTxn(() async {
            await isar.tokenModels.clear();
            await isar.tokenModels.put(tokenModel);
          });

          await initializeApp();
          expect(initDone, isTrue);

          final client = initData.client!;
          await client.init();
          await client.getLessons(
            DateTime.now(),
            DateTime.now().add(const Duration(days: 10)),
          );

          final cachedStarts = client.cache
              .getTimeTable()
              .findAllSync()
              .map((l) => l.start)
              .toSet();

          expect(
            cachedStarts.length,
            2,
            reason:
                'both occurrences of the recurring slot should be cached as '
                'distinct rows on their own dates — a cacheKey collision '
                'would leave only one row, dated whichever occurrence was '
                'written last',
          );
        });
      },
    );
  });
}
