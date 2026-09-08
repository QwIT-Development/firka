import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/alarm_notification_service.dart';
import 'package:firka/services/fcm_service.dart';

class NotificationDeliveryService {
  static final Logger _logger = Logger('NotificationDeliveryService');
  static const MethodChannel _mainChannel = MethodChannel('firka.app/main');

  static bool? _cachedGmsAvailable;

  @visibleForTesting
  static bool? gmsAvailabilityOverride;

  @visibleForTesting
  static bool? isAndroidOverride;

  static bool get _isAndroid => isAndroidOverride ?? Platform.isAndroid;

  @visibleForTesting
  static void resetForTesting() {
    _cachedGmsAvailable = null;
    gmsAvailabilityOverride = null;
    isAndroidOverride = null;
  }

  static Future<bool> isGmsAvailable({bool forceRefresh = false}) async {
    if (gmsAvailabilityOverride != null) {
      return gmsAvailabilityOverride!;
    }
    if (!_isAndroid) return false;
    if (_cachedGmsAvailable != null && !forceRefresh) {
      return _cachedGmsAvailable!;
    }
    try {
      final available = await _mainChannel.invokeMethod<bool>('isGmsAvailable');
      _cachedGmsAvailable = available ?? false;
      return _cachedGmsAvailable!;
    } catch (e) {
      _logger.warning('Error checking GMS availability: $e');
      _cachedGmsAvailable = false;
      return false;
    }
  }

  static Future<NotificationDeliveryMethod> getEffectiveMethod() async {
    final configured = Settings.notificationDeliveryMethod.value;
    if (configured != NotificationDeliveryMethod.auto) {
      return configured;
    }
    final gms = await isGmsAvailable();
    return gms ? NotificationDeliveryMethod.fcm : NotificationDeliveryMethod.alarm;
  }

  static Future<void> initialize() async {
    if (!_isAndroid) return;

    final gms = await isGmsAvailable();
    _logger.info('Initializing NotificationDeliveryService (GMS available: $gms)');

    await AlarmNotificationService.initialize();

    if (gms) {
      await FcmService.initialize();
    }

    await syncDeliveryBackend();
  }

  static Future<void> syncDeliveryBackend() async {
    if (!_isAndroid) return;

    try {
      if (!Settings.notifyAll.value) {
        _logger.info('Push notifications disabled, tearing down delivery backends');
        await FcmService.handleEnabledChange(false);
        await AlarmNotificationService.cancel();
        return;
      }

      final effectiveMethod = await getEffectiveMethod();
      _logger.info('Syncing delivery backend for effective method: $effectiveMethod');

      switch (effectiveMethod) {
        case NotificationDeliveryMethod.fcm:
          await AlarmNotificationService.cancel();
          await FcmService.handleEnabledChange(true);
          break;
        case NotificationDeliveryMethod.alarm:
          await FcmService.handleEnabledChange(false);
          await AlarmNotificationService.schedule();
          break;
        case NotificationDeliveryMethod.auto:
          break;
      }
    } catch (e, st) {
      _logger.warning('Failed to sync delivery backend: $e', e, st);
    }
  }

  static Future<void> handleWakeupIntervalChange() async {
    if (!Settings.notifyAll.value) return;

    final effectiveMethod = await getEffectiveMethod();
    if (effectiveMethod == NotificationDeliveryMethod.fcm) {
      await FcmService.handleWakeupIntervalChange();
    } else if (effectiveMethod == NotificationDeliveryMethod.alarm) {
      await AlarmNotificationService.schedule();
    }
  }

  static Future<void> onUserLogin({required KretaClient client}) async {
    if (!_isAndroid) return;

    try {
      final effectiveMethod = await getEffectiveMethod();
      if (effectiveMethod == NotificationDeliveryMethod.fcm) {
        await FcmService.onUserLogin(client: client);
      } else if (effectiveMethod == NotificationDeliveryMethod.alarm) {
        await AlarmNotificationService.schedule();
      }
    } catch (e, st) {
      _logger.warning('Failed to process onUserLogin: $e', e, st);
    }
  }

  static Future<void> onUserLogout() async {
    if (!_isAndroid) return;

    final effectiveMethod = await getEffectiveMethod();
    if (effectiveMethod == NotificationDeliveryMethod.fcm) {
      await FcmService.onUserLogout();
    } else if (effectiveMethod == NotificationDeliveryMethod.alarm) {
      final tokenCount = await isarInit.tokenModels.count();
      if (tokenCount == 0) {
        await AlarmNotificationService.cancel();
      }
    }
  }
}
