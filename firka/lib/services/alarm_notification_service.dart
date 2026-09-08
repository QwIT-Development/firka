import 'dart:async';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/notification_diff_service.dart';

const int _alarmNotificationSyncId = 910001;

@pragma('vm:entry-point')
Future<void> alarmNotificationWakeupCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationDiffService.checkAll();
}

class AlarmNotificationService {
  static final Logger _logger = Logger('AlarmNotificationService');
  static bool _isInitialized = false;

  @visibleForTesting
  static bool? isAndroidOverride;

  static bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;

  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
    isAndroidOverride = null;
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized || !_isAndroid) return;
    try {
      await AndroidAlarmManager.initialize();
      _isInitialized = true;
      _logger.info('AlarmNotificationService initialized');
    } catch (e, st) {
      _logger.severe('Failed to initialize AlarmNotificationService: $e', e, st);
    }
  }

  static Duration _durationFor(NotifyWakeupInterval interval) {
    switch (interval) {
      case NotifyWakeupInterval.hourly:
        return const Duration(hours: 1);
      case NotifyWakeupInterval.twoHourly:
        return const Duration(hours: 2);
    }
  }

  static Future<void> schedule() async {
    if (!_isAndroid) return;
    try {
      await initialize();
      final interval = _durationFor(Settings.notifyWakeupInterval.value);
      await AndroidAlarmManager.cancel(_alarmNotificationSyncId);
      await AndroidAlarmManager.periodic(
        interval,
        _alarmNotificationSyncId,
        alarmNotificationWakeupCallback,
        exact: false,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      _logger.info('Scheduled periodic alarm every ${interval.inHours}h');
    } catch (e, st) {
      _logger.severe('Failed to schedule alarm: $e', e, st);
    }
  }

  static Future<void> cancel() async {
    if (!_isAndroid) return;
    try {
      await AndroidAlarmManager.cancel(_alarmNotificationSyncId);
      _logger.info('Cancelled periodic alarm');
    } catch (e, st) {
      _logger.warning('Failed to cancel alarm: $e', e, st);
    }
  }
}
