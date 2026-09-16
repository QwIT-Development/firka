// ignore_for_file: depend_on_referenced_packages
//
// Isolates whether the monthly calendar's lesson-count flicker is a
// UI/query bug or comes from upstream data churn during sync.
import 'dart:convert';
import 'dart:io';

import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/core/bloc/profile_picture_cubit.dart';
import 'package:firka/core/bloc/settings_cubit.dart';
import 'package:firka/core/bloc/toast_cubit.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/phone/pages/home/home_timetable_mo.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:logging/logging.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

const _mockServerUrl = 'http://127.0.0.1:8090';

class _RealHttpOverrides extends HttpOverrides {}

class _MockNotificationsPlatform extends FlutterLocalNotificationsPlatform
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

Future<TokenGrantResponse> _authenticateMockServer(HttpClient httpClient) async {
  final loginReq = await httpClient.getUrl(
    Uri.parse('$_mockServerUrl/Account/Login'),
  );
  final loginResp = await loginReq.close();
  final loginBody = await loginResp.transform(utf8.decoder).join();
  final match = RegExp(r'name="code" value="([^"]+)"').firstMatch(loginBody);
  final code = match!.group(1)!;

  final tokenReq = await httpClient.postUrl(
    Uri.parse('$_mockServerUrl/connect/token'),
  );
  tokenReq.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
  tokenReq.write('grant_type=authorization_code&code=${Uri.encodeQueryComponent(code)}');
  final tokenResp = await tokenReq.close();
  final tokenBody = await tokenResp.transform(utf8.decoder).join();
  return TokenGrantResponse.fromJson(jsonDecode(tokenBody) as Map<String, dynamic>);
}

Future<void> _resetMockServer(HttpClient httpClient) async {
  final req = await httpClient.postUrl(Uri.parse('$_mockServerUrl/admin/api/reset'));
  final resp = await req.close();
  await resp.drain();
}

Future<void> _putTimetable(
  HttpClient httpClient,
  List<Map<String, dynamic>> lessons,
) async {
  final req = await httpClient.putUrl(Uri.parse('$_mockServerUrl/admin/api/timetable'));
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
    'TanarNeve': 'Teszt Tanár',
    'Tantargy': {
      'Uid': '1,MATEK',
      'Nev': name,
      'Kategoria': {'Uid': '1', 'Nev': 'Kötelező', 'Leiras': 'Kötelező tantárgy'},
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
  FlutterLocalNotificationsPlatform.instance = _MockNotificationsPlatform();
  logger = Logger('TimetableMonthWidgetFlickerTest');

  testWidgets(
    'repeated HomeRefreshCubit triggers never drop an already-rendered '
    'day\'s lesson count when the underlying data is unchanged',
    (tester) async {
      HttpOverrides.global = _RealHttpOverrides();
      final httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 5);

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

      await tester.runAsync(() async {
        await _resetMockServer(httpClient);
        // Lessons on 3 different days within the visible 49-day grid.
        await _putTimetable(httpClient, [
          _lesson(uid: 'd0', start: '07:30', end: '08:15', name: 'Matematika', daysFromToday: 0),
          _lesson(uid: 'd5', start: '07:30', end: '08:15', name: 'Fizika', daysFromToday: 5),
          _lesson(uid: 'd12', start: '07:30', end: '08:15', name: 'Kémia', daysFromToday: 12),
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
        // Make sure the whole visible grid (7 weeks) is actually synced,
        // not just renewCache's default 2-week window.
        await client.getLessonsCovering(
          DateTime.now().subtract(const Duration(days: 21)),
          DateTime.now().add(const Duration(days: 28)),
        );
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: initData.settingsCubit),
            BlocProvider<ProfilePictureCubit>.value(
              value: initData.profilePictureCubit,
            ),
            BlocProvider<ToastCubit>.value(value: initData.toastCubit),
            BlocProvider<HomeRefreshCubit>.value(
              value: initData.homeRefreshCubit,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeTimetableMonthlyScreen(initData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read the badge Text out of each cell directly — scanning all
      // on-screen Text would also match the day-of-month labels.
      List<String?> badgeTexts() {
        final columns = tester
            .widgetList<Column>(
              find.descendant(
                of: find.byType(GridView),
                matching: find.byType(Column),
              ),
            )
            .toList();
        return columns.map((col) {
          final container = col.children.first as Container;
          final body = container.child;
          if (body is Center && body.child is Text) {
            return (body.child as Text).data;
          }
          return null;
        }).toList();
      }

      final baseline = badgeTexts();
      final baselineNonEmptyCount = baseline.whereType<String>().length;
      expect(
        baselineNonEmptyCount,
        greaterThanOrEqualTo(3),
        reason:
            'sanity check: the 3 seeded days should show non-empty lesson '
            'count badges before any refresh trigger fires',
      );

      var everLostABadge = false;
      for (var i = 0; i < 15; i++) {
        initData.homeRefreshCubit.requestRefresh();
        await tester.pump();
        final current = badgeTexts();
        for (var cell = 0; cell < baseline.length; cell++) {
          if (baseline[cell] != null && current[cell] == null) {
            everLostABadge = true;
          }
        }
        if (everLostABadge) break;
      }

      expect(
        everLostABadge,
        isFalse,
        reason:
            'a day that had a lesson-count badge lost it after a pure UI '
            'refresh trigger, with no network activity and unchanged Isar '
            'data — this would be a genuine widget/query bug, not server '
            'data variability',
      );

      httpClient.close(force: true);
    },
  );
}
