// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/alarm_notification_service.dart';
import 'package:firka/services/local_notification_service.dart';
import 'package:firka/services/notification_diff_service.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:logging/logging.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _mockServerUrl = 'http://127.0.0.1:8090';

class _RealHttpOverrides extends HttpOverrides {}

Future<TokenGrantResponse> _authenticateMockServer(HttpClient httpClient) async {
  final loginReq = await httpClient.getUrl(Uri.parse('$_mockServerUrl/Account/Login'));
  final loginResp = await loginReq.close();
  final loginBody = await loginResp.transform(utf8.decoder).join();

  final match = RegExp(r'name="code" value="([^"]+)"').firstMatch(loginBody);
  if (match == null) {
    throw Exception('Failed to extract code from mock server login: $loginBody');
  }
  final code = match.group(1)!;

  final tokenReq = await httpClient.postUrl(Uri.parse('$_mockServerUrl/connect/token'));
  tokenReq.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
  tokenReq.write('grant_type=authorization_code&code=${Uri.encodeQueryComponent(code)}');
  final tokenResp = await tokenReq.close();
  final tokenBody = await tokenResp.transform(utf8.decoder).join();
  if (tokenResp.statusCode != 200) {
    throw Exception('Token request failed (${tokenResp.statusCode}): $tokenBody');
  }
  return TokenGrantResponse.fromJson(jsonDecode(tokenBody) as Map<String, dynamic>);
}

Future<void> _postItem(HttpClient httpClient, String endpoint, Map<String, dynamic> item) async {
  final req = await httpClient.postUrl(Uri.parse('$_mockServerUrl$endpoint'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(item));
  final resp = await req.close();
  if (resp.statusCode != 200 && resp.statusCode != 204) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('POST $endpoint failed (${resp.statusCode}): $body');
  }
}

Future<void> _seedMockLessonsToday(HttpClient httpClient) async {
  final req = await httpClient.postUrl(Uri.parse('$_mockServerUrl/admin/api/timetable/today'));
  final resp = await req.close();
  if (resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to shift lessons to today (${resp.statusCode}): $body');
  }
}

class MockNotificationsPlatform extends FlutterLocalNotificationsPlatform
    with MockPlatformInterfaceMixin {
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {}

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();
  FlutterLocalNotificationsPlatform.instance = MockNotificationsPlatform();
  logger = Logger("NotificationDiffTest");

  group('Notification System End-to-End Test with Mock Kreta Server', () {
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

    testWidgets('Synthetic FCM wakeup diffs changes correctly and posts notifications', (tester) async {
      HttpOverrides.global = _RealHttpOverrides();

      await tester.runAsync(() async {
        await _seedMockLessonsToday(httpClient);

        final isar = await initDB();
        await isar.writeTxn(() async {
          await isar.clear();
        });
        Settings = SettingsRepository(isar);
        await Settings.loadAll();

        await Settings.mockBackendEnabled.set(true);
        await Settings.mockBackendUrl.set(_mockServerUrl);
        await Settings.notifyAll.set(true);
        await Settings.notifyGrades.set(true);
        await Settings.notifyHomeworkTests.set(true);
        await Settings.notifyLessons.set(true);
        await Settings.notifyAbsences.set(true);
        await Settings.notifyMessages.set(true);
        await Settings.notifyMutedSubjects.set('[]');

        final tokenResp = await _authenticateMockServer(httpClient);
        final tokenModel = TokenModel.fromResp(tokenResp);

        await isar.writeTxn(() async {
          await isar.tokenModels.clear();
          await isar.tokenModels.put(tokenModel);
        });

        await initializeApp();
        expect(initDone, isTrue);

        if (initData.client != null) {
          await initData.client!.init();
          await initData.client!.renewCache(reInit: false);
        }

        LocalNotificationService.postedNotifications.clear();
        await NotificationDiffService.checkAll();
        expect(LocalNotificationService.postedNotifications, isEmpty);

        LocalNotificationService.postedNotifications.clear();
        final newGradeUid = 'test-grade-${DateTime.now().millisecondsSinceEpoch}';
        final newGradeTime = DateTime.now().toUtc().toIso8601String();
        await _postItem(httpClient, '/admin/api/grades', {
          'Uid': newGradeUid,
          'RogzitesDatuma': newGradeTime,
          'KeszitesDatuma': newGradeTime,
          'Tantargy': {
            'Uid': '10,INF',
            'Nev': 'Informatika',
            'Kategoria': {'Uid': '1', 'Nev': 'Kötelező'},
            'SortIndex': 10,
          },
          'Tema': 'Algoritmusok',
          'Tipus': {'Uid': '1', 'Nev': 'Gyakorlati feladat'},
          'ErtekFajta': {'Uid': '1', 'Nev': 'Osztályzat'},
          'ErtekeloTanarNeve': 'Turing Alan',
          'Jelleg': 'Ertekeles',
          'SzamErtek': 5,
          'SzovegesErtek': 'Jeles',
          'SulySzazalekErteke': 100,
          'OsztalyCsoport': {'Uid': '10,11.A'},
        });

        await NotificationDiffService.checkAll();
        expect(LocalNotificationService.postedNotifications, isNotEmpty);
        final gradeNotif = LocalNotificationService.postedNotifications.firstWhere(
          (n) => n.title.contains('jegy'),
        );
        expect(gradeNotif.title, contains('jegy'));
        expect(gradeNotif.body, contains('Informatika'));

        LocalNotificationService.postedNotifications.clear();
        final newHwUid = 'test-hw-${DateTime.now().millisecondsSinceEpoch}';
        final newHwTime = DateTime.now().toUtc().toIso8601String();
        await _postItem(httpClient, '/admin/api/homework', {
          'Uid': newHwUid,
          'Tantargy': {
            'Uid': '11,BIO',
            'Nev': 'Biológia',
            'Kategoria': {'Uid': '1', 'Nev': 'Kötelező'},
            'SortIndex': 11,
          },
          'TantargyNeve': 'Biológia',
          'RogzitoTanarNeve': 'Darwin Károly',
          'Szoveg': 'Olvassátok el a sejtbiológia fejezetet.',
          'FeladasDatuma': newHwTime,
          'HataridoDatuma': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
          'RogzitesIdopontja': newHwTime,
          'IsTanarRogzitette': true,
          'IsMegoldva': false,
          'IsBeadhato': false,
          'OsztalyCsoport': {'Uid': '10,11.A'},
        });

        await NotificationDiffService.checkAll();
        expect(LocalNotificationService.postedNotifications, isNotEmpty);
        final hwNotif = LocalNotificationService.postedNotifications.firstWhere(
          (n) => n.title.contains('házi feladat'),
        );
        expect(hwNotif.title, contains('házi feladat'));
        expect(hwNotif.body, contains('Biológia'));

        LocalNotificationService.postedNotifications.clear();
        await _postItem(httpClient, '/admin/api/timetable/mutate', {
          'Uid': '5000',
          'Nev': 'Matematika',
          'HelyettesTanarNeve': 'Prof. Helyettes',
          'Allapot': {
            'Uid': '1',
            'Nev': 'Megtartott',
            'Leiras': 'Megtartott óra',
          },
          'Tipus': {
            'Uid': '1',
            'Nev': 'Tanóra',
            'Leiras': 'Tanóra',
          },
          'UtolsoModositas': DateTime.now().toUtc().toIso8601String(),
        });

        await NotificationDiffService.checkAll();
        expect(LocalNotificationService.postedNotifications, isNotEmpty);
        final subNotif = LocalNotificationService.postedNotifications.firstWhere(
          (n) => n.title.contains('Helyettesítés'),
        );
        expect(subNotif.title, equals('Helyettesítés'));
        expect(subNotif.body, contains('Prof. Helyettes'));

        LocalNotificationService.postedNotifications.clear();
        await _postItem(httpClient, '/admin/api/timetable/mutate', {
          'Uid': '5000',
          'Nev': 'Matematika',
          'Allapot': {
            'Uid': '3',
            'Nev': 'Elmaradt',
            'Leiras': 'Elmaradt óra',
          },
          'Tipus': {
            'Uid': 'UresOra',
            'Nev': 'UresOra',
            'Leiras': 'Lyukasóra',
          },
          'UtolsoModositas': DateTime.now().toUtc().toIso8601String(),
        });

        await NotificationDiffService.checkAll();
        expect(LocalNotificationService.postedNotifications, isNotEmpty);
        final cancelNotif = LocalNotificationService.postedNotifications.firstWhere(
          (n) => n.title.contains('Elmaradt óra'),
        );
        expect(cancelNotif.title, equals('Elmaradt óra'));

        LocalNotificationService.postedNotifications.clear();
        await Settings.notifyMutedSubjects.set(jsonEncode(['Fizika']));

        final mutedGradeUid = 'test-grade-muted-${DateTime.now().millisecondsSinceEpoch}';
        final mutedGradeTime = DateTime.now().toUtc().toIso8601String();
        await _postItem(httpClient, '/admin/api/grades', {
          'Uid': mutedGradeUid,
          'RogzitesDatuma': mutedGradeTime,
          'KeszitesDatuma': mutedGradeTime,
          'Tantargy': {
            'Uid': '12,FIZ',
            'Nev': 'Fizika',
            'Kategoria': {'Uid': '1', 'Nev': 'Kötelező'},
            'SortIndex': 12,
          },
          'Tema': 'Mechanika',
          'Tipus': {'Uid': '1', 'Nev': 'Írásbeli'},
          'ErtekFajta': {'Uid': '1', 'Nev': 'Osztályzat'},
          'ErtekeloTanarNeve': 'Newton Izsák',
          'Jelleg': 'Ertekeles',
          'SzamErtek': 5,
          'SzovegesErtek': 'Jeles',
          'SulySzazalekErteke': 100,
          'OsztalyCsoport': {'Uid': '10,11.A'},
        });

        await NotificationDiffService.checkAll();

        final fizikaNotifs = LocalNotificationService.postedNotifications
            .where((n) => n.body.contains('Fizika') || n.body.contains('Newton'))
            .toList();
        expect(fizikaNotifs, isEmpty);

        LocalNotificationService.postedNotifications.clear();
        final alarmGradeUid = 'test-grade-alarm-${DateTime.now().millisecondsSinceEpoch}';
        final alarmGradeTime = DateTime.now().toUtc().toIso8601String();
        await _postItem(httpClient, '/admin/api/grades', {
          'Uid': alarmGradeUid,
          'RogzitesDatuma': alarmGradeTime,
          'KeszitesDatuma': alarmGradeTime,
          'Tantargy': {
            'Uid': '14,TOR',
            'Nev': 'Történelem',
            'Kategoria': {'Uid': '1', 'Nev': 'Kötelező'},
            'SortIndex': 14,
          },
          'Tema': 'Középkor',
          'Tipus': {'Uid': '1', 'Nev': 'Szóbeli'},
          'ErtekFajta': {'Uid': '1', 'Nev': 'Osztályzat'},
          'ErtekeloTanarNeve': 'Hérodotosz',
          'Jelleg': 'Ertekeles',
          'SzamErtek': 5,
          'SzovegesErtek': 'Jeles',
          'SulySzazalekErteke': 100,
          'OsztalyCsoport': {'Uid': '10,11.A'},
        });

        await alarmNotificationWakeupCallback();

        final alarmNotif = LocalNotificationService.postedNotifications.firstWhere(
          (n) => n.title.contains('jegy') && n.body.contains('Történelem'),
        );
        expect(alarmNotif.title, contains('jegy'));
        expect(alarmNotif.body, contains('Történelem'));
      });
    });
  });
}
