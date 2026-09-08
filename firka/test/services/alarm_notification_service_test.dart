import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/alarm_notification_service.dart';
import 'package:firka_common/data/database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const alarmChannel = MethodChannel(
    'dev.fluttercommunity.plus/android_alarm_manager',
    JSONMethodCodec(),
  );

  late Directory tempDir;
  late List<MethodCall> alarmCalls;

  setUp(() async {
    alarmCalls = [];
    AlarmNotificationService.resetForTesting();
    AlarmNotificationService.isAndroidOverride = true;

    tempDir = Directory.systemTemp.createTempSync('alarm_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      alarmChannel,
      (MethodCall call) async {
        alarmCalls.add(call);
        return true;
      },
    );

    AndroidAlarmManager.setTestOverrides(
      getCallbackHandle: (_) => CallbackHandle.fromRawHandle(42),
    );

    final isar = await initDB();
    await isar.writeTxn(() async {
      await isar.clear();
    });
    Settings = SettingsRepository(isar);
    await Settings.loadAll();
  });

  tearDown(() async {
    AlarmNotificationService.resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('initialize invokes AlarmService.start', () async {
    await AlarmNotificationService.initialize();
    expect(AlarmNotificationService.isInitialized, isTrue);
    expect(alarmCalls.any((call) => call.method == 'AlarmService.start'), isTrue);
  });

  test('schedule sets up hourly periodic alarm with sync ID 910001', () async {
    await Settings.notifyWakeupInterval.set(NotifyWakeupInterval.hourly);
    await AlarmNotificationService.schedule();

    final periodicCalls = alarmCalls.where((call) => call.method == 'Alarm.periodic').toList();
    expect(periodicCalls, isNotEmpty);
    final call = periodicCalls.last;
    expect(call.arguments[0], 910001);
    expect(call.arguments[3], isTrue); // wakeup
    expect(call.arguments[5], const Duration(hours: 1).inMilliseconds);
    expect(call.arguments[6], isTrue); // rescheduleOnReboot
  });

  test('schedule sets up two-hourly periodic alarm when configured', () async {
    await Settings.notifyWakeupInterval.set(NotifyWakeupInterval.twoHourly);
    await AlarmNotificationService.schedule();

    final periodicCalls = alarmCalls.where((call) => call.method == 'Alarm.periodic').toList();
    expect(periodicCalls, isNotEmpty);
    final call = periodicCalls.last;
    expect(call.arguments[0], 910001);
    expect(call.arguments[3], isTrue); // wakeup
    expect(call.arguments[5], const Duration(hours: 2).inMilliseconds);
    expect(call.arguments[6], isTrue); // rescheduleOnReboot
  });

  test('cancel invokes Alarm.cancel with sync ID 910001', () async {
    await AlarmNotificationService.cancel();

    final cancelCalls = alarmCalls.where((call) => call.method == 'Alarm.cancel').toList();
    expect(cancelCalls, isNotEmpty);
    expect(cancelCalls.last.arguments[0], 910001);
  });
}
