import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/alarm_notification_service.dart';
import 'package:firka/services/notification_delivery_service.dart';
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
    NotificationDeliveryService.resetForTesting();
    AlarmNotificationService.resetForTesting();
    NotificationDeliveryService.isAndroidOverride = true;
    AlarmNotificationService.isAndroidOverride = true;

    tempDir = Directory.systemTemp.createTempSync('delivery_test_');

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
    NotificationDeliveryService.resetForTesting();
    AlarmNotificationService.resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('NotificationDeliveryService effective method resolution', () {
    test('resolves explicit FCM setting', () async {
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.fcm);
      final effective = await NotificationDeliveryService.getEffectiveMethod();
      expect(effective, NotificationDeliveryMethod.fcm);
    });

    test('resolves explicit Alarm setting', () async {
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
      final effective = await NotificationDeliveryService.getEffectiveMethod();
      expect(effective, NotificationDeliveryMethod.alarm);
    });

    test('auto resolves to FCM when GMS is available', () async {
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.auto);
      NotificationDeliveryService.gmsAvailabilityOverride = true;

      final effective = await NotificationDeliveryService.getEffectiveMethod();
      expect(effective, NotificationDeliveryMethod.fcm);
    });

    test('auto resolves to Alarm when GMS is unavailable', () async {
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.auto);
      NotificationDeliveryService.gmsAvailabilityOverride = false;

      final effective = await NotificationDeliveryService.getEffectiveMethod();
      expect(effective, NotificationDeliveryMethod.alarm);
    });
  });

  group('NotificationDeliveryService backend coordination & settings effects', () {
    test('syncDeliveryBackend cancels alarm when notifyAll is disabled', () async {
      await Settings.notifyAll.set(false);
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);

      alarmCalls.clear();
      await NotificationDeliveryService.syncDeliveryBackend();

      final cancelCalls = alarmCalls.where((c) => c.method == 'Alarm.cancel').toList();
      expect(cancelCalls, isNotEmpty);
      expect(cancelCalls.last.arguments[0], 910001);
    });

    test('syncDeliveryBackend schedules alarm when method is alarm and notifyAll is true', () async {
      await Settings.notifyAll.set(true);
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
      await Settings.notifyWakeupInterval.set(NotifyWakeupInterval.hourly);

      alarmCalls.clear();
      await NotificationDeliveryService.syncDeliveryBackend();

      final periodicCalls = alarmCalls.where((c) => c.method == 'Alarm.periodic').toList();
      expect(periodicCalls, isNotEmpty);
      expect(periodicCalls.last.arguments[0], 910001);
      expect(periodicCalls.last.arguments[5], const Duration(hours: 1).inMilliseconds);
    });

    test('syncDeliveryBackend cancels alarm when switching from alarm to fcm', () async {
      await Settings.notifyAll.set(true);
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
      await NotificationDeliveryService.syncDeliveryBackend();

      alarmCalls.clear();
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.fcm);
      await NotificationDeliveryService.syncDeliveryBackend();

      final cancelCalls = alarmCalls.where((c) => c.method == 'Alarm.cancel').toList();
      expect(cancelCalls, isNotEmpty);
      expect(cancelCalls.last.arguments[0], 910001);
    });

    test('handleWakeupIntervalChange reschedules alarm with new duration', () async {
      await Settings.notifyAll.set(true);
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
      await Settings.notifyWakeupInterval.set(NotifyWakeupInterval.twoHourly);

      alarmCalls.clear();
      await NotificationDeliveryService.handleWakeupIntervalChange();

      final periodicCalls = alarmCalls.where((c) => c.method == 'Alarm.periodic').toList();
      expect(periodicCalls, isNotEmpty);
      expect(periodicCalls.last.arguments[5], const Duration(hours: 2).inMilliseconds);
    });

    test('changing settings triggers registered settings effects', () async {
      Settings.onChange(SettingsRegistry.notifyAll, (_) async {
        await NotificationDeliveryService.syncDeliveryBackend();
      });
      Settings.onChange(SettingsRegistry.notificationDeliveryMethod, (_) async {
        await NotificationDeliveryService.syncDeliveryBackend();
      });
      Settings.onChange(SettingsRegistry.notifyWakeupInterval, (_) async {
        await NotificationDeliveryService.handleWakeupIntervalChange();
      });

      await Settings.notifyAll.set(true);
      alarmCalls.clear();

      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
      expect(alarmCalls.any((c) => c.method == 'Alarm.periodic'), isTrue);

      alarmCalls.clear();
      await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.fcm);
      expect(alarmCalls.any((c) => c.method == 'Alarm.cancel'), isTrue);
    });
  });
}
