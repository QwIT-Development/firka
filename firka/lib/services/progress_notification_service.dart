import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';

import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/data/widget.dart';
import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/services/notification_delivery_service.dart';

class ProgressNotificationService {
  static final Logger _logger = Logger('ProgressNotificationService');
  static const MethodChannel _channel = MethodChannel('app.firka/progress_notification');

  @visibleForTesting
  static bool? isAndroidOverride;

  static bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;

  /// Syncs notification string templates from Flutter ARB localizations to Android SharedPreferences.
  static Future<void> syncStrings([AppLocalizations? l10n]) async {
    if (!_isAndroid) return;
    try {
      l10n ??= initDone ? initData.l10n : null;
      if (l10n == null) return;
      final strings = <String, String>{
        'progress_notif_channel_name': l10n.progress_notif_channel_name,
        'progress_notif_channel_desc': l10n.progress_notif_channel_desc,
        'progress_notif_lesson_title': l10n.progress_notif_lesson_title('{number}', '{name}'),
        'progress_notif_substitution': l10n.progress_notif_substitution,
        'progress_notif_case1_text': l10n.progress_notif_case1_text(
          '{minutes}',
          '{timeRange}',
          '{room}',
          '{substitution}',
          '{remaining}',
        ),
        'progress_notif_case2_lesson_text': l10n.progress_notif_case2_lesson_text(
          '{minutes}',
          '{timeRange}',
          '{room}',
          '{substitution}',
          '{remaining}',
        ),
        'progress_notif_case2_break_title': l10n.progress_notif_case2_break_title,
        'progress_notif_case2_break_text': l10n.progress_notif_case2_break_text(
          '{minutes}',
          '{remaining}',
        ),
        'progress_notif_critical_text': l10n.progress_notif_critical_text('{minutes}'),
        'progress_notif_remaining_lessons_one': l10n.progress_notif_remaining_lessons_one,
        'progress_notif_remaining_lessons_other': l10n.progress_notif_remaining_lessons_other('{count}'),
      };
      await _channel.invokeMethod<bool>('updateProgressStrings', strings);
      _logger.info('Synced progress notification strings to native platform');
    } catch (e, st) {
      _logger.warning('Failed to sync progress notification strings: $e', e, st);
    }
  }

  static Future<bool> startService() async {
    if (!_isAndroid) return false;
    try {
      await syncStrings();
      final res = await _channel.invokeMethod<bool>('startProgressService');
      _logger.info('Started ProgressNotificationForegroundService: $res');
      return res ?? true;
    } catch (e, st) {
      _logger.warning('Failed to start ProgressNotificationForegroundService: $e', e, st);
      return false;
    }
  }

  static Future<bool> stopService() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopProgressService');
      _logger.info('Stopped ProgressNotificationForegroundService: $res');
      return res ?? true;
    } catch (e, st) {
      _logger.warning('Failed to stop ProgressNotificationForegroundService: $e', e, st);
      return false;
    }
  }

  static Future<bool> schedule6AmAlarm() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('schedule6AmAlarm');
      _logger.info('Scheduled 6 AM progress alarm: $res');
      return res ?? true;
    } catch (e, st) {
      _logger.warning('Failed to schedule 6 AM progress alarm: $e', e, st);
      return false;
    }
  }

  static Future<bool> cancel6AmAlarm() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('cancel6AmAlarm');
      _logger.info('Cancelled 6 AM progress alarm: $res');
      return res ?? true;
    } catch (e, st) {
      _logger.warning('Failed to cancel 6 AM progress alarm: $e', e, st);
      return false;
    }
  }

  static Future<bool> isRunning() async {
    if (!_isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isProgressServiceRunning');
      return res ?? false;
    } catch (e, st) {
      _logger.warning('Failed to check if progress service is running: $e', e, st);
      return false;
    }
  }

  /// Syncs service state based on current settings and delivery method.
  static Future<void> sync() async {
    if (!_isAndroid) return;

    await syncStrings();

    final isEnabled = Settings.progressNotificationEnabled.value && Settings.notifyAll.value;
    if (!isEnabled) {
      _logger.info('Progress notifications disabled, stopping service and cancelling alarm');
      await stopService();
      await cancel6AmAlarm();
      return;
    }

    final deliveryMethod = await NotificationDeliveryService.getEffectiveMethod();
    if (deliveryMethod == NotificationDeliveryMethod.alarm) {
      await schedule6AmAlarm();
    } else {
      await cancel6AmAlarm();
    }

    await checkAndStartIfActive();
  }

  /// Checks if current time is on/after the start date (first lesson start)
  /// and before the last lesson ends. If so, and the progress-centric
  /// notification is not running, starts it up.
  static Future<void> checkAndStartOnAppOpen() async {
    if (!_isAndroid) return;
    if (!Settings.progressNotificationEnabled.value || !Settings.notifyAll.value) return;

    try {
      final now = timeNow();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      var lessons = await isarInit.lessonCacheModels
          .filter()
          .startBetween(startOfDay, endOfDay)
          .sortByStart()
          .findAll();

      if (lessons.isEmpty) {
        lessons = await isarInit.lessonCacheModels
            .filter()
            .on(now)
            .sortByStart()
            .findAll();
      }

      // Cancelled lessons don't happen; ignore them (matches the native service).
      lessons = lessons
          .where((l) => !l.state.toLowerCase().contains('elmarad'))
          .toList();

      if (lessons.isEmpty) {
        _logger.info('No lessons for today; not starting progress service on app open');
        return;
      }

      final firstLesson = lessons.first;
      final lastLesson = lessons.last;
      final startDate = firstLesson.start;

      final isAboveStartDate = now.isAfter(startDate) || now.isAtSameMomentAs(startDate);
      final isBelowLastLesson = now.isBefore(lastLesson.end);

      if (!isAboveStartDate) {
        _logger.info('Current time ($now) is before start date ($startDate); not starting progress service');
        return;
      }

      if (!isBelowLastLesson) {
        _logger.info('Current time ($now) is after last lesson end (${lastLesson.end}); stopping/not starting progress service');
        final running = await isRunning();
        if (running) {
          await stopService();
        }
        return;
      }

      final running = await isRunning();
      if (!running) {
        _logger.info('Time is within school day and progress service is not running; starting up');
        await WidgetCacheHelper.updateWidgetCacheFromIsar();
        await startService();
      } else {
        _logger.info('Progress service is already running');
      }
    } catch (e, st) {
      _logger.warning('Error in checkAndStartOnAppOpen: $e', e, st);
    }
  }

  /// Checks if today has lessons and if current time is within active bounds.
  static Future<void> checkAndStartIfActive() async {
    await checkAndStartOnAppOpen();
  }

  /// Called on app startup in the morning.
  static Future<void> checkAndStartOnMorning() async {
    await sync();
  }
}
