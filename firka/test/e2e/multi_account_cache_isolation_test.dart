// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
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

Future<void> _putCollection(
  HttpClient httpClient,
  String endpoint,
  List<Map<String, dynamic>> items,
) async {
  final req = await httpClient.putUrl(Uri.parse('$_mockServerUrl$endpoint'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(items));
  final resp = await req.close();
  if (resp.statusCode != 204 && resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to PUT $endpoint (${resp.statusCode}): $body');
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

Map<String, dynamic> _grade(String uid) => {
  'Uid': uid,
  'RogzitesDatuma': '2026-09-08T00:00:00',
  'KeszitesDatuma': '2026-09-08T00:00:00',
  'Tantargy': {
    'Uid': '1,MATEK',
    'Nev': 'Matematika',
    'Kategoria': {'Uid': '1', 'Nev': 'Kötelező', 'Leiras': 'Kötelező tantárgy'},
    'SortIndex': 1,
  },
  'Tema': 'Teszt téma',
  'Tipus': {'Uid': '1', 'Nev': 'Írásbeli', 'Leiras': 'Írásbeli felelet'},
  'ErtekFajta': {'Uid': '1', 'Nev': 'Osztályzat', 'Leiras': 'Osztályzat'},
  'ErtekeloTanarNeve': 'Teszt Tanár',
  'Jelleg': 'Ertekeles',
  'SzamErtek': 5,
  'SzovegesErtek': 'Jeles',
  'SulySzazalekErteke': 100,
  'OsztalyCsoport': {'Uid': '10,11.A'},
  'SortIndex': 1,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterLocalNotificationsPlatform.instance = MockNotificationsPlatform();
  logger = Logger('MultiAccountCacheIsolationTest');

  group('Multi-account cache isolation', () {
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
      'resyncing one account does not delete another account\'s cached rows',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();

        await tester.runAsync(() async {
          await _resetMockServer(httpClient);
          await _putCollection(httpClient, '/admin/api/timetable', [
            _lesson(
              uid: '9001',
              start: '07:30',
              end: '08:15',
              name: 'Matematika',
            ),
            _lesson(uid: '9002', start: '08:25', end: '09:10', name: 'Fizika'),
            _lesson(uid: '9003', start: '09:20', end: '10:05', name: 'Kémia'),
          ]);
          await _putCollection(httpClient, '/admin/api/grades', [
            _grade('g-1'),
          ]);

          final isar = await initDB();
          await isar.writeTxn(() async {
            await isar.clear();
          });
          Settings = SettingsRepository(isar);
          await Settings.loadAll();
          await Settings.mockBackendEnabled.set(true);
          await Settings.mockBackendUrl.set(_mockServerUrl);

          // mock server is single-tenant. a cloned token with a different iss gets its own cache.
          final tokenResp = await _authenticateMockServer(httpClient);
          final tokenA = TokenModel.fromResp(tokenResp);
          // studentId must match the server's real id. isCurrentStudent matches on it.
          final tokenB = TokenModel()
            ..key = tokenA.key + 1
            ..studentId = tokenA.studentId
            ..username = '${tokenA.username}-b'
            ..iss = '${tokenA.iss}-b'
            ..idToken = tokenA.idToken
            ..accessToken = tokenA.accessToken
            ..refreshToken = tokenA.refreshToken
            ..expiryDate = tokenA.expiryDate
            ..tokenVersion = tokenA.tokenVersion
            ..updatedAtMs = tokenA.updatedAtMs;

          await isar.writeTxn(() async {
            await isar.tokenModels.clear();
            await isar.tokenModels.put(tokenA);
            await isar.tokenModels.put(tokenB);
          });

          await initializeApp();
          expect(initDone, isTrue);

          final clientA = KretaClient(tokenA);
          final clientB = KretaClient(tokenB);

          await clientA.init();
          await clientA.renewCache(reInit: false);
          await clientB.init();
          await clientB.renewCache(reInit: false);

          List<LessonCacheModel> lessonsFor(KretaClient client) {
            final today = DateTime.now();
            bool isToday(DateTime d) =>
                d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
            return client.cache
                .getTimeTable()
                .findAllSync()
                .where((l) => isToday(l.start))
                .toList();
          }

          expect(lessonsFor(clientA).length, 3);
          expect(lessonsFor(clientB).length, 3);
          expect(clientB.cache.getGrades().findAllSync().length, 1);

          // account A's timetable and grade get edited server-side
          await _putCollection(httpClient, '/admin/api/timetable', [
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
          await _putCollection(httpClient, '/admin/api/grades', []);
          await clientA.renewCache(reInit: false);

          final aAfter = lessonsFor(clientA);
          expect(
            aAfter.length,
            3,
            reason: 'account A should still reconcile correctly',
          );
          final aFizika = aAfter.firstWhere((l) => l.name == 'Fizika');
          expect(
            aFizika.start.minute,
            20,
            reason: "account A should see its own edited copy",
          );
          expect(clientA.cache.getGrades().findAllSync(), isEmpty);

          final bAfter = lessonsFor(clientB);
          expect(
            bAfter.length,
            3,
            reason: "account B's lessons must survive account A's resync",
          );
          expect(bAfter.map((l) => l.name).toSet(), {
            'Matematika',
            'Fizika',
            'Kémia',
          });
          // lesson name is identical on both sides. start time reveals the account.
          final bFizika = bAfter.firstWhere((l) => l.name == 'Fizika');
          expect(bFizika.start.hour, 8);
          expect(bFizika.start.minute, 25);

          final bGrades = clientB.cache.getGrades().findAllSync();
          expect(
            bGrades.length,
            1,
            reason:
                "account B's grade must survive account A's grade being cleared",
          );
          expect(
            bGrades.single.cacheKey,
            clientB.cache.genCacheKey(UidObj(uid: 'g-1')),
            reason:
                "the surviving row must be account B's own copy of g-1, not "
                "some row aliased in from account A",
          );
        });
      },
    );
  });
}
