// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

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
}) {
  final today = DateTime.now();
  final datePrefix =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return {
    'Uid': uid,
    'Datum': '${datePrefix}T00:00:00',
    'KezdetIdopont': '${datePrefix}T$start:00',
    'VegIdopont': '${datePrefix}T$end:00',
    'Nev': name,
    'OsztalyCsoport': {'Uid': '10,11.A', 'Nev': '11.A'},
    'TanarNeve': 'Teszt Tanár',
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
    'TeremNeve': '101',
    'Tipus': {'Uid': '1', 'Nev': 'Tanóra', 'Leiras': 'Tanóra'},
    'TanuloJelenlet': {'Uid': '', 'Nev': '', 'Leiras': ''},
    'Allapot': {'Uid': '1', 'Nev': 'Megtartott', 'Leiras': 'Megtartott óra'},
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
  });
}
