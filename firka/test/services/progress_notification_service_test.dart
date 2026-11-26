import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/l10n/app_localizations_en.dart';
import 'package:firka/l10n/app_localizations_hu.dart';
import 'package:firka/services/notification_delivery_service.dart';
import 'package:firka/services/progress_notification_service.dart';
import 'package:isar_community/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const progressChannel = MethodChannel('app.firka/progress_notification');
  late Directory tempDir;
  late List<MethodCall> progressCalls;

  setUp(() async {
    progressCalls = [];
    ProgressNotificationService.isAndroidOverride = true;
    NotificationDeliveryService.isAndroidOverride = true;
    NotificationDeliveryService.resetForTesting();
    NotificationDeliveryService.gmsAvailabilityOverride = true;

    tempDir = Directory.systemTemp.createTempSync('progress_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      progressChannel,
      (MethodCall call) async {
        progressCalls.add(call);
        return true;
      },
    );

    final isar = await initDB();
    await isar.writeTxn(() async {
      await isar.clear();
    });
    Settings = SettingsRepository(isar);
    await Settings.loadAll();
  });

  tearDown(() async {
    debugFakeTime = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('progressNotificationEnabled setting defaults to false and can be toggled', () async {
    expect(Settings.progressNotificationEnabled.value, isFalse);
    await Settings.progressNotificationEnabled.set(true);
    expect(Settings.progressNotificationEnabled.value, isTrue);
    await Settings.progressNotificationEnabled.set(false);
    expect(Settings.progressNotificationEnabled.value, isFalse);
  });

  test('startService and stopService invoke appropriate method channel methods', () async {
    final startRes = await ProgressNotificationService.startService();
    expect(startRes, isTrue);
    expect(progressCalls.any((c) => c.method == 'startProgressService'), isTrue);

    final stopRes = await ProgressNotificationService.stopService();
    expect(stopRes, isTrue);
    expect(progressCalls.any((c) => c.method == 'stopProgressService'), isTrue);
  });

  test('schedule6AmAlarm and cancel6AmAlarm invoke appropriate method channel methods', () async {
    final schedRes = await ProgressNotificationService.schedule6AmAlarm();
    expect(schedRes, isTrue);
    expect(progressCalls.any((c) => c.method == 'schedule6AmAlarm'), isTrue);

    final cancelRes = await ProgressNotificationService.cancel6AmAlarm();
    expect(cancelRes, isTrue);
    expect(progressCalls.any((c) => c.method == 'cancel6AmAlarm'), isTrue);
  });

  test('sync stops service and cancels alarm when disabled', () async {
    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(false);
    progressCalls.clear();

    await ProgressNotificationService.sync();

    expect(progressCalls.any((c) => c.method == 'stopProgressService'), isTrue);
    expect(progressCalls.any((c) => c.method == 'cancel6AmAlarm'), isTrue);
  });

  test('sync schedules 6 AM alarm when delivery method is alarm', () async {
    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);
    await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.alarm);
    progressCalls.clear();

    await ProgressNotificationService.sync();

    expect(progressCalls.any((c) => c.method == 'schedule6AmAlarm'), isTrue);
  });

  test('sync cancels 6 AM alarm when delivery method is FCM (triggers via FCM wakeup)', () async {
    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);
    await Settings.notificationDeliveryMethod.set(NotificationDeliveryMethod.fcm);
    progressCalls.clear();

    await ProgressNotificationService.sync();

    expect(progressCalls.any((c) => c.method == 'cancel6AmAlarm'), isTrue);
  });

  LessonCacheModel makeLesson(String uid, String name, DateTime start, DateTime end) {
    return LessonCacheModel()
      ..cacheKey = Isar.autoIncrement
      ..createdAt = DateTime.now()
      ..uid = uid
      ..name = name
      ..state = 'normal'
      ..type = 'lesson'
      ..start = start
      ..end = end;
  }

  test('isRunning queries method channel isProgressServiceRunning', () async {
    progressCalls.clear();
    final running = await ProgressNotificationService.isRunning();
    expect(running, isTrue);
    expect(progressCalls.any((c) => c.method == 'isProgressServiceRunning'), isTrue);
  });

  test('checkAndStartOnAppOpen does not start when time is before first lesson start', () async {
    final isar = isarInit;
    final today = DateTime.now();
    final lesson1 = makeLesson('l1', 'Math', DateTime(today.year, today.month, today.day, 8, 0), DateTime(today.year, today.month, today.day, 8, 45));
    final lesson2 = makeLesson('l2', 'History', DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 9, 45));

    await isar.writeTxn(() async {
      await isar.lessonCacheModels.putAll([lesson1, lesson2]);
    });

    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);

    // Set time before first lesson (07:30)
    debugFakeTime = DateTime(today.year, today.month, today.day, 7, 30);
    progressCalls.clear();

    await ProgressNotificationService.checkAndStartOnAppOpen();

    expect(progressCalls.any((c) => c.method == 'startProgressService'), isFalse);
  });

  test('checkAndStartOnAppOpen starts service when time is within school day and service is not running', () async {
    final isar = isarInit;
    final today = DateTime.now();
    final lesson1 = makeLesson('l1', 'Math', DateTime(today.year, today.month, today.day, 8, 0), DateTime(today.year, today.month, today.day, 8, 45));
    final lesson2 = makeLesson('l2', 'History', DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 9, 45));

    await isar.writeTxn(() async {
      await isar.lessonCacheModels.putAll([lesson1, lesson2]);
    });

    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);

    // Mock isProgressServiceRunning returning false
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      progressChannel,
      (MethodCall call) async {
        progressCalls.add(call);
        if (call.method == 'isProgressServiceRunning') return false;
        return true;
      },
    );

    // Set time inside school day (08:20)
    debugFakeTime = DateTime(today.year, today.month, today.day, 8, 20);
    progressCalls.clear();

    await ProgressNotificationService.checkAndStartOnAppOpen();

    expect(progressCalls.any((c) => c.method == 'isProgressServiceRunning'), isTrue);
    expect(progressCalls.any((c) => c.method == 'startProgressService'), isTrue);
  });

  test('checkAndStartOnAppOpen does not start service when already running', () async {
    final isar = isarInit;
    final today = DateTime.now();
    final lesson1 = makeLesson('l1', 'Math', DateTime(today.year, today.month, today.day, 8, 0), DateTime(today.year, today.month, today.day, 8, 45));
    final lesson2 = makeLesson('l2', 'History', DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 9, 45));

    await isar.writeTxn(() async {
      await isar.lessonCacheModels.putAll([lesson1, lesson2]);
    });

    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);

    // Mock isProgressServiceRunning returning true
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      progressChannel,
      (MethodCall call) async {
        progressCalls.add(call);
        if (call.method == 'isProgressServiceRunning') return true;
        return true;
      },
    );

    // Set time inside school day (08:20)
    debugFakeTime = DateTime(today.year, today.month, today.day, 8, 20);
    progressCalls.clear();

    await ProgressNotificationService.checkAndStartOnAppOpen();

    expect(progressCalls.any((c) => c.method == 'isProgressServiceRunning'), isTrue);
    expect(progressCalls.any((c) => c.method == 'startProgressService'), isFalse);
  });

  test('checkAndStartOnAppOpen stops service and does not start when time is after last lesson end', () async {
    final isar = isarInit;
    final today = DateTime.now();
    final lesson1 = makeLesson('l1', 'Math', DateTime(today.year, today.month, today.day, 8, 0), DateTime(today.year, today.month, today.day, 8, 45));
    final lesson2 = makeLesson('l2', 'History', DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 9, 45));

    await isar.writeTxn(() async {
      await isar.lessonCacheModels.putAll([lesson1, lesson2]);
    });

    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);

    // Mock isProgressServiceRunning returning true
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      progressChannel,
      (MethodCall call) async {
        progressCalls.add(call);
        if (call.method == 'isProgressServiceRunning') return true;
        return true;
      },
    );

    // Set time after last lesson (10:00)
    debugFakeTime = DateTime(today.year, today.month, today.day, 10, 0);
    progressCalls.clear();

    await ProgressNotificationService.checkAndStartOnAppOpen();

    expect(progressCalls.any((c) => c.method == 'startProgressService'), isFalse);
    expect(progressCalls.any((c) => c.method == 'stopProgressService'), isTrue);
  });

  test('checkAndStartOnAppOpen ignores cancelled lessons when computing the school day', () async {
    final isar = isarInit;
    final today = DateTime.now();
    final lesson1 = makeLesson('l1', 'Math', DateTime(today.year, today.month, today.day, 8, 0), DateTime(today.year, today.month, today.day, 8, 45));
    final cancelled = makeLesson('l2', 'History', DateTime(today.year, today.month, today.day, 9, 0), DateTime(today.year, today.month, today.day, 9, 45))
      ..state = 'Elmaradt';

    await isar.writeTxn(() async {
      await isar.lessonCacheModels.putAll([lesson1, cancelled]);
    });

    await Settings.notifyAll.set(true);
    await Settings.progressNotificationEnabled.set(true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      progressChannel,
      (MethodCall call) async {
        progressCalls.add(call);
        if (call.method == 'isProgressServiceRunning') return true;
        return true;
      },
    );

    // 09:10 falls inside the cancelled lesson, which is after the last real lesson.
    debugFakeTime = DateTime(today.year, today.month, today.day, 9, 10);
    progressCalls.clear();

    await ProgressNotificationService.checkAndStartOnAppOpen();

    expect(progressCalls.any((c) => c.method == 'startProgressService'), isFalse);
    expect(progressCalls.any((c) => c.method == 'stopProgressService'), isTrue);
  });

  test('syncStrings sends Hungarian strings map to native platform without Unicode symbols', () async {
    progressCalls.clear();
    await ProgressNotificationService.syncStrings(AppLocalizationsHu());
    final call = progressCalls.firstWhere((c) => c.method == 'updateProgressStrings');
    final map = call.arguments as Map;
    expect(map['progress_notif_channel_name'], 'Tanítási nap folyamata');
    expect(map['progress_notif_channel_desc'], 'Élő értesítés a mai órák és szünetek állapotáról');
    expect(map['progress_notif_lesson_title'], '{number}. óra: {name}');
    expect(map['progress_notif_substitution'], ' (Helyettesítés)');
    expect(map['progress_notif_case1_text'], '{minutes} perc múlva ({timeRange}){room}{substitution}{remaining}');
    expect(map['progress_notif_case2_lesson_text'], '{minutes} perc van hátra ({timeRange}){room}{substitution}{remaining}');
    expect(map['progress_notif_case2_break_title'], 'Szünet');
    expect(map['progress_notif_case2_break_text'], '{minutes} perc van hátra{remaining}');
    expect(map['progress_notif_critical_text'], '{minutes}p');
    expect(map['progress_notif_remaining_lessons_one'], ' - Még 1 óra van hátra');
    expect(map['progress_notif_remaining_lessons_other'], ' - Még {count} óra van hátra');

    // Verify none of the strings contain Unicode bullet
    for (final val in map.values) {
      expect((val as String).contains('•'), isFalse);
    }
  });

  test('syncStrings sends English strings map to native platform without Unicode symbols', () async {
    progressCalls.clear();
    await ProgressNotificationService.syncStrings(AppLocalizationsEn());
    final call = progressCalls.firstWhere((c) => c.method == 'updateProgressStrings');
    final map = call.arguments as Map;
    expect(map['progress_notif_channel_name'], 'School day progress');
    expect(map['progress_notif_channel_desc'], "Live progress notification for today's lessons and breaks");
    expect(map['progress_notif_lesson_title'], 'Lesson {number}: {name}');
    expect(map['progress_notif_substitution'], ' (Substitution)');
    expect(map['progress_notif_case1_text'], 'In {minutes} min ({timeRange}){room}{substitution}{remaining}');
    expect(map['progress_notif_case2_lesson_text'], '{minutes} min left ({timeRange}){room}{substitution}{remaining}');
    expect(map['progress_notif_case2_break_title'], 'Break');
    expect(map['progress_notif_case2_break_text'], '{minutes} min left{remaining}');
    expect(map['progress_notif_critical_text'], '{minutes}m');
    expect(map['progress_notif_remaining_lessons_one'], ' - 1 lesson remaining');
    expect(map['progress_notif_remaining_lessons_other'], ' - {count} lessons remaining');

    // Verify none of the strings contain Unicode bullet
    for (final val in map.values) {
      expect((val as String).contains('•'), isFalse);
    }
  });
}
