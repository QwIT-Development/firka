// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
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

const _subject = {
  'Uid': '1,MATEK',
  'Nev': 'Matematika',
  'Kategoria': {'Uid': '1', 'Nev': 'Kötelező', 'Leiras': 'Kötelező tantárgy'},
  'SortIndex': 1,
};

Map<String, dynamic> _grade(String uid) => {
  'Uid': uid,
  'RogzitesDatuma': '2026-09-08T00:00:00',
  'KeszitesDatuma': '2026-09-08T00:00:00',
  'Tantargy': _subject,
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

Map<String, dynamic> _homework(String uid) => {
  'Uid': uid,
  'Tantargy': _subject,
  'TantargyNeve': 'Matematika',
  'RogzitoTanarNeve': 'Teszt Tanár',
  'Szoveg': 'Teszt házi feladat',
  'FeladasDatuma': '2026-09-09T00:00:00',
  'HataridoDatuma': '2026-09-16T00:00:00',
  'RogzitesIdopontja': '2026-09-09T00:00:00',
  'IsTanarRogzitette': true,
  'IsMegoldva': false,
  'IsBeadhato': false,
  'OsztalyCsoport': {'Uid': '10,11.A'},
  'IsCsatolasEngedelyezes': false,
};

Map<String, dynamic> _test(String uid) => {
  'Uid': uid,
  'Datum': '2026-09-14T00:00:00',
  'BejelentesDatuma': '2026-09-09T00:00:00',
  'RogzitoTanarNeve': 'Teszt Tanár',
  'OrarendiOraOraszama': 2,
  'Tantargy': _subject,
  'TantargyNeve': 'Matematika',
  'Temaja': 'Teszt dolgozat téma',
  'Modja': {'Uid': '1', 'Nev': 'Írásbeli', 'Leiras': 'Írásbeli dolgozat'},
  'OsztalyCsoport': {'Uid': '10,11.A'},
};

Map<String, dynamic> _omission(String uid) => {
  'Uid': uid,
  'Tantargy': _subject,
  'Ora': {
    'KezdoDatum': '2026-09-07T00:00:00',
    'VegDatum': '2026-09-07T00:45:00',
    'Oraszam': 1,
  },
  'Datum': '2026-09-07T00:00:00',
  'RogzitoTanarNeve': 'Teszt Tanár',
  'Tipus': {'Uid': '1', 'Nev': 'Hiányzás', 'Leiras': 'Hiányzás'},
  'Mod': {'Uid': '', 'Nev': '', 'Leiras': ''},
  'KeszitesDatuma': '2026-09-07T00:00:00',
  'IgazolasAllapota': 'Igazolt',
  'IgazolasTipusa': {'Uid': '', 'Nev': '', 'Leiras': ''},
  'OsztalyCsoport': {'Uid': '10,11.A'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterLocalNotificationsPlatform.instance = MockNotificationsPlatform();
  logger = Logger('CollectionCacheReconciliationTest');

  group('Collection cache reconciliation against mock Kreta server', () {
    late HttpClient httpClient;

    setUp(() async {
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

    Future<void> initAndSync() async {
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

      await initData.client!.init();
      await initData.client!.renewCache(reInit: false);
    }

    testWidgets('stale grade rows are removed after a server-side correction', (
      tester,
    ) async {
      HttpOverrides.global = _RealHttpOverrides();
      await tester.runAsync(() async {
        await _resetMockServer(httpClient);
        await _putCollection(httpClient, '/admin/api/grades', [
          _grade('g-1'),
          _grade('g-2'),
        ]);

        await initAndSync();
        expect(isarInit.gradeCacheModels.where().findAllSync().length, 2);

        // teacher deletes an erroneously entered grade server-side
        await _putCollection(httpClient, '/admin/api/grades', [_grade('g-1')]);
        await initData.client!.renewCache(reInit: false);

        expect(
          isarInit.gradeCacheModels.where().findAllSync().length,
          1,
          reason: 'deleted grade should no longer be cached locally',
        );
      });
    });

    testWidgets(
      'stale homework rows are removed after a server-side deletion',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();
        await tester.runAsync(() async {
          await _resetMockServer(httpClient);
          await _putCollection(httpClient, '/admin/api/homework', [
            _homework('h-1'),
            _homework('h-2'),
          ]);

          await initAndSync();
          expect(isarInit.homeworkCacheModels.where().findAllSync().length, 2);

          await _putCollection(httpClient, '/admin/api/homework', [
            _homework('h-1'),
          ]);
          await initData.client!.renewCache(reInit: false);

          expect(
            isarInit.homeworkCacheModels.where().findAllSync().length,
            1,
            reason: 'deleted homework should no longer be cached locally',
          );
        });
      },
    );

    testWidgets(
      'stale test rows are removed after a server-side cancellation',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();
        await tester.runAsync(() async {
          await _resetMockServer(httpClient);
          await _putCollection(httpClient, '/admin/api/tests', [
            _test('t-1'),
            _test('t-2'),
          ]);

          await initAndSync();
          expect(isarInit.testCacheModels.where().findAllSync().length, 2);

          await _putCollection(httpClient, '/admin/api/tests', [_test('t-1')]);
          await initData.client!.renewCache(reInit: false);

          expect(
            isarInit.testCacheModels.where().findAllSync().length,
            1,
            reason: 'cancelled test should no longer be cached locally',
          );
        });
      },
    );

    testWidgets(
      'stale omission rows are removed after a server-side justification',
      (tester) async {
        HttpOverrides.global = _RealHttpOverrides();
        await tester.runAsync(() async {
          await _resetMockServer(httpClient);
          await _putCollection(httpClient, '/admin/api/omissions', [
            _omission('o-1'),
            _omission('o-2'),
          ]);

          await initAndSync();
          expect(isarInit.omissionCacheModels.where().findAllSync().length, 2);

          // a teacher retroactively removes an incorrectly recorded absence
          await _putCollection(httpClient, '/admin/api/omissions', [
            _omission('o-1'),
          ]);
          await initData.client!.renewCache(reInit: false);

          expect(
            isarInit.omissionCacheModels.where().findAllSync().length,
            1,
            reason: 'removed absence should no longer be cached locally',
          );
        });
      },
    );
  });
}
