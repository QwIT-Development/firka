import 'dart:convert';
import 'dart:io';

import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/data/widget.dart';
import 'package:firka/services/notification_diff_service.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _mockServerUrl = 'http://127.0.0.1:8090';

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

Future<List<Map<String, dynamic>>> _getMockLessons(HttpClient httpClient) async {
  final req = await httpClient.getUrl(Uri.parse('$_mockServerUrl/admin/api/lessons'));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final list = jsonDecode(body) as List;
  return list.cast<Map<String, dynamic>>();
}

Future<void> _putMockLessons(HttpClient httpClient, List<Map<String, dynamic>> lessons) async {
  final req = await httpClient.putUrl(Uri.parse('$_mockServerUrl/admin/api/lessons'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(lessons));
  final resp = await req.close();
  if (resp.statusCode != 204 && resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to update mock lessons (${resp.statusCode}): $body');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  logger = Logger("FirkaTest");
  dio.options.connectTimeout = const Duration(seconds: 5);
  dio.options.receiveTimeout = const Duration(seconds: 3);
  dio.options.validateStatus = (status) => status != null && status < 500;

  group('Widget End-to-End Test with Mock Kreta Server', () {
    late HttpClient httpClient;

    setUp(() {
      httpClient = HttpClient();
    });

    tearDown(() {
      httpClient.close(force: true);
    });

    testWidgets('Opening app updates widget with timetable and FCM wakeup syncs timetable changes', (tester) async {
      // 1. Initialize DB and authenticate with mock_kreta_server
      final isar = await initDB();
      Settings = SettingsRepository(isar);
      await Settings.loadAll();

      // Configure mock backend settings and enable notifications
      await Settings.mockBackendEnabled.set(true);
      await Settings.mockBackendUrl.set(_mockServerUrl);
      await Settings.notifyAll.set(true);

      final originalLessons = await _getMockLessons(httpClient);
      final today = DateTime.now();
      final seededLessons = originalLessons.indexed.map((entry) {
        final (i, l) = entry;
        final m = Map<String, dynamic>.from(l);
        m['KezdetIdopont'] = DateTime(today.year, today.month, today.day, 8 + i, 0).toIso8601String();
        m['VegIdopont'] = DateTime(today.year, today.month, today.day, 8 + i, 45).toIso8601String();
        return m;
      }).toList();
      await _putMockLessons(httpClient, seededLessons);

      final tokenResp = await _authenticateMockServer(httpClient);
      final tokenModel = TokenModel.fromResp(tokenResp);

      await isar.writeTxn(() async {
        await isar.tokenModels.clear();
        await isar.tokenModels.put(tokenModel);
      });

      // 2. Initialize app (simulates opening the app)
      await initializeApp();
      expect(initDone, isTrue);

      if (initData.client != null) {
        await initData.client!.init();
        await initData.client!.renewCache(reInit: false);
        await WidgetCacheHelper.updateWidgetCacheFromIsar();
      }

      final dataDir = await getApplicationDocumentsDirectory();
      final widgetFile = File(p.join(dataDir.path, 'widget_state.json'));

      // Verify that widget_state.json was created on app opening
      expect(widgetFile.existsSync(), isTrue, reason: 'widget_state.json must exist after opening app');

      final initialContent = jsonDecode(widgetFile.readAsStringSync()) as Map<String, dynamic>;
      expect(initialContent.containsKey('colors'), isTrue);
      expect(initialContent.containsKey('timetable'), isTrue);

      final initialTimetable = (initialContent['timetable'] as List).cast<Map<String, dynamic>>();
      expect(initialTimetable.isNotEmpty, isTrue, reason: 'Timetable in widget must not be empty');

      final firstLessonName = initialTimetable.first['name'];
      expect(firstLessonName, isNotNull);
      expect(initialTimetable.first.containsKey('dailyNth'), isTrue);
      expect(initialTimetable.first.containsKey('start'), isTrue);
      expect(initialTimetable.first.containsKey('end'), isTrue);

      // 3. Simulate timetable change on mock server
      final currentMockLessons = await _getMockLessons(httpClient);
      expect(currentMockLessons.isNotEmpty, isTrue);

      // Mutate the target lesson: change room and assign a substitute teacher
      final modifiedLessons = List<Map<String, dynamic>>.from(currentMockLessons);
      final targetIndex = modifiedLessons.indexWhere((l) => l['Nev'] == firstLessonName);
      expect(targetIndex != -1, isTrue);
      final updatedLesson = Map<String, dynamic>.from(modifiedLessons[targetIndex]);
      updatedLesson['TeremNeve'] = 'LAB-999';
      updatedLesson['HelyettesTanarNeve'] = 'Prof. E2E Teszt';
      modifiedLessons[targetIndex] = updatedLesson;

      await _putMockLessons(httpClient, modifiedLessons);

      // 4. Trigger FCM wakeup processing
      await NotificationDiffService.checkAll();

      // 5. Verify widget_state.json was updated with modified timetable
      final updatedContent = jsonDecode(widgetFile.readAsStringSync()) as Map<String, dynamic>;
      final updatedTimetable = (updatedContent['timetable'] as List).cast<Map<String, dynamic>>();

      final updatedMatch = updatedTimetable.firstWhere(
        (l) => l['name'] == firstLessonName,
        orElse: () => <String, dynamic>{},
      );
      expect(updatedMatch.isNotEmpty, isTrue);
      expect(updatedMatch['roomName'], equals('LAB-999'), reason: 'Widget state should have updated room name');
      expect(updatedMatch['substituteTeacher'], equals('Prof. E2E Teszt'), reason: 'Widget state should have updated substitute teacher');

      // Revert mock server lessons back to original
      await _putMockLessons(httpClient, originalLessons);
    });
  });
}
