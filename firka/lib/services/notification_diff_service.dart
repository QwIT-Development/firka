import 'dart:convert';

import 'package:isar_community/isar.dart';

import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/last_seen.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:logging/logging.dart';

import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/core/last_seen_helper.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka/services/fcm_headless_bootstrap.dart';
import 'package:firka/services/local_notification_service.dart';

/// Runs on a silent FCM wakeup: for every locally logged-in account, fetches
/// grades/homework/tests/absences/lessons/messages, diffs each against what
/// was last seen by *this pipeline* (see LastSeenHelper's notif* kinds,
/// which are deliberately separate from the UI's "opened" tracking), and
/// shows a local notification per category with genuinely new items.
class NotificationDiffService {
  static final Logger _logger = Logger('NotificationDiffService');

  static Future<void> checkAll() async {
    await bootstrapHeadless();
    await LocalNotificationService.init();

    if (!Settings.notifyAll.value) {
      _logger.info('checkAll: push disabled, skipping');
      return;
    }

    final tokens = await isarInit.tokenModels.where().findAll();
    for (final token in tokens) {
      try {
        final client = KretaClient(token);
        await _checkAccount(client, token.key, token.username);
      } catch (e, st) {
        _logger.warning('checkAll: account ${token.username} failed: $e', e, st);
      }
    }
  }

  static Future<void> _checkAccount(
    KretaClient client,
    int accountKey,
    String username,
  ) async {
    final mutedSubjects = _mutedSubjects();

    if (Settings.notifyGrades.value) {
      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifGrades,
        items: _excludeMuted(await client.getGrades(), mutedSubjects, (g) => g.subject.value?.name),
        title: (n) => n.length == 1 ? 'Új jegy érkezett' : '${n.length} új jegy érkezett',
        body: (n) => n
            .map((g) => '${g.subject.value?.name ?? "?"}: ${g.textValue} (${_fmtDate(g.writtenAt)})')
            .take(5)
            .join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifGrades),
      );
    }

    if (Settings.notifyHomeworkTests.value) {
      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifHomework,
        items: _excludeMuted(await client.getHomework(), mutedSubjects, (h) => h.subject.value?.name),
        title: (n) => n.length == 1 ? 'Új házi feladat' : '${n.length} új házi feladat',
        body: (n) => n.map((h) => h.subject.value?.name ?? "?").take(5).join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifHomework),
      );

      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifTests,
        items: await client.getTests(),
        title: (n) => n.length == 1 ? 'Új témazáró/dolgozat' : '${n.length} új témazáró/dolgozat',
        body: (n) => n.map((t) => t.topic ?? t.method).take(5).join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifTests),
      );
    }

    if (Settings.notifyAbsences.value) {
      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifAbsences,
        items: await client.getOmissions(),
        title: (n) => n.length == 1 ? 'Új hiányzás/késés' : '${n.length} új hiányzás/késés',
        body: (n) => n.map((o) => o.state.name).take(5).join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifAbsences),
      );
    }

    if (Settings.notifyLessons.value) {
      final now = DateTime.now();
      final lessons = await client.getLessons(now, now.add(const Duration(days: 7)));

      final cancelled = lessons.where(_isCancelledLesson).toList();
      final substituted = lessons
          .where((l) => !_isCancelledLesson(l) && l.substituteTeacher != null)
          .toList();
      final otherChanges = lessons
          .where((l) => !_isCancelledLesson(l) && l.substituteTeacher == null)
          .toList();

      // Split into three separately-diffed notifications instead of one lump
      // "schedule changed" — cancellations and substitutions carry which
      // teacher and (for cancellations) that Kréta doesn't give a free-text
      // reason, only the state label, so that's the most that's shown.
      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifLessonsCancelled,
        items: cancelled,
        title: (n) => n.length == 1 ? 'Elmaradt óra' : '${n.length} elmaradt óra',
        body: (n) => n
            .map(
              (l) =>
                  '${l.subject.value?.name ?? l.name} - ${l.teacher ?? "?"} '
                  '(${_fmtDateTime(l.start)})',
            )
            .take(5)
            .join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifLessonsCancelled),
      );

      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifLessonsSubstituted,
        items: substituted,
        title: (n) => n.length == 1 ? 'Helyettesítés' : '${n.length} helyettesítés',
        body: (n) => n
            .map(
              (l) =>
                  '${l.subject.value?.name ?? l.name}: ${l.teacher ?? "?"} -> '
                  '${l.substituteTeacher} (${_fmtDateTime(l.start)})',
            )
            .take(5)
            .join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifLessonsSubstituted),
      );

      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifLessons,
        items: otherChanges,
        title: (n) => n.length == 1
            ? 'Órarendváltozás'
            : '${n.length} órarendváltozás',
        body: (n) => n
            .map((l) => '${l.subject.value?.name ?? l.name} (${l.roomName ?? "?"})')
            .take(5)
            .join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifLessons),
      );
    }

    if (Settings.notifyMessages.value) {
      final combined = [
        ...await client.getNoticeBoard(),
        ...await client.getInfoBoard(),
      ];
      await _diffAndNotify(
        accountKey: accountKey,
        kind: LastSeenHelper.notifMessages,
        items: combined,
        title: (n) => n.length == 1 ? 'Új üzenet' : '${n.length} új üzenet',
        body: (n) => n.map((m) => m.title).take(5).join(', '),
        notificationId: _notificationId(accountKey, LastSeenHelper.notifMessages),
      );
    }
  }

  /// Diffs [items] against the stored last-seen marker for (accountKey,
  /// kind). On the very first run for an account+kind there's no baseline
  /// yet, so it seeds one silently instead of notifying about the entire
  /// historical backlog.
  static Future<void> _diffAndNotify<T extends GenericCacheModel>({
    required int accountKey,
    required String kind,
    required List<T> items,
    required String Function(List<T> newItems) title,
    required String Function(List<T> newItems) body,
    required int notificationId,
  }) async {
    final seen = LastSeenHelper.get(accountKey, kind);

    if (seen != null) {
      final newItems = LastSeen.newerThan(items, seen);
      if (newItems.isNotEmpty) {
        await LocalNotificationService.show(
          id: notificationId,
          title: title(newItems),
          body: body(newItems),
        );
      }
    }

    final newest = LastSeen.newestOf(items);
    if (newest != null) {
      await LastSeenHelper.set(accountKey, kind, newest);
    }
  }

  /// Muted-subject filtering only applies where the model has a directly
  /// resolvable subject link populated during fetch (grades, homework).
  /// Tests/lessons/absences/messages don't carry a reliably-loaded subject
  /// reference at this point, so they're never muted by subject.
  static List<T> _excludeMuted<T>(
    List<T> items,
    Set<String> mutedSubjects,
    String? Function(T) subjectOf,
  ) {
    if (mutedSubjects.isEmpty) return items;
    return items.where((i) => !mutedSubjects.contains(subjectOf(i))).toList();
  }

  static Set<String> _mutedSubjects() {
    try {
      final decoded = jsonDecode(Settings.notifyMutedSubjects.value);
      if (decoded is List) return decoded.whereType<String>().toSet();
    } catch (_) {}
    return const {};
  }

  static int _notificationId(int accountKey, String kind) =>
      Object.hash(accountKey, kind) & 0x7fffffff;

  /// Matches the "isCancelled" convention already used across the app's
  /// live-activity/widget code (state names aren't a stable enum, just a
  /// Kréta-provided label; "elmarad" is the substring that consistently
  /// shows up for cancelled lessons across localizations seen so far).
  static bool _isCancelledLesson(LessonCacheModel l) =>
      l.state.toLowerCase().contains('elmarad');

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Sample content per category for [showTestNotification]. `titleSingle`
  /// matches the wording `_checkAccount` uses for a lone new item on a
  /// single-account device; `titleMulti` drops the possessive so it reads
  /// naturally with a "(username)" suffix appended per account.
  static const _testContent = {
    LastSeenHelper.notifGrades: (
      titleSingle: 'Új jegyed érkezett',
      titleMulti: 'Új jegy érkezett',
      body: 'Matematika: 5 (2026-01-02)',
    ),
    LastSeenHelper.notifHomework: (
      titleSingle: 'Új házi feladatod érkezett',
      titleMulti: 'Új házi feladat érkezett',
      body: 'Történelem: Olvasd el a 24. fejezetet (határidő: 2026-01-05)',
    ),
    LastSeenHelper.notifTests: (
      titleSingle: 'Új témazáród/dolgozatod érkezett',
      titleMulti: 'Új témazáró/dolgozat érkezett',
      body: 'Fizika: Mechanika témazáró (2026-01-09 10:00)',
    ),
    LastSeenHelper.notifAbsences: (
      titleSingle: 'Új hiányzásod/késésed érkezett',
      titleMulti: 'Új hiányzás/késés érkezett',
      body: 'Kémia: Igazolatlan hiányzás (2026-01-02 09:00)',
    ),
    LastSeenHelper.notifLessons: (
      titleSingle: 'Órarendváltozás történt',
      titleMulti: 'Órarendváltozás történt',
      body: 'Kémia (A-002, 2026-01-06 12:00)',
    ),
    LastSeenHelper.notifLessonsCancelled: (
      titleSingle: 'Elmaradt órád van',
      titleMulti: 'Elmaradt óra',
      body: 'Testnevelés - Nagy Béla (2026-01-06 12:00)',
    ),
    LastSeenHelper.notifLessonsSubstituted: (
      titleSingle: 'Helyettesítés van az órarendedben',
      titleMulti: 'Helyettesítés',
      body: 'Kémia: Nagy Béla -> Kovács Anna (2026-01-06 09:50)',
    ),
    LastSeenHelper.notifMessages: (
      titleSingle: 'Új üzeneted érkezett',
      titleMulti: 'Új üzenet érkezett',
      body: 'Nulladik óra átnevezése első órára - Müller Attila (2026-01-15 07:42)',
    ),
  };

  static const _simulatedUsernames = ['Gipsz Jakab', 'Kis Anna'];

  /// Fires a local notification with placeholder content for [kind], for
  /// eyeballing what each category looks like on-device without needing
  /// real new data from the backend. Bypasses last-seen diffing entirely,
  /// so it always shows regardless of what's already been seen.
  ///
  /// With a single account logged in (the common case), shows one
  /// notification with the personalized singular title. With more than one
  /// account, fires one per account instead, with the impersonal title
  /// suffixed by that account's username so they're distinguishable — this
  /// mirrors what a real multi-account wakeup would look like, since
  /// [checkAll] runs the diff separately per account. Pass
  /// [simulateMultiAccount] to preview that layout without needing a second
  /// account actually logged in on this device.
  static Future<void> showTestNotification(
    String kind, {
    bool simulateMultiAccount = false,
  }) async {
    final content = _testContent[kind];
    if (content == null) return;
    await LocalNotificationService.init();

    final usernames = simulateMultiAccount
        ? _simulatedUsernames
        : (await isarInit.tokenModels.where().findAll())
              .map((t) => t.username)
              .toList();

    if (usernames.length <= 1) {
      await LocalNotificationService.show(
        id: _notificationId(0, kind),
        title: content.titleSingle,
        body: content.body,
      );
      return;
    }

    for (var i = 0; i < usernames.length; i++) {
      await LocalNotificationService.show(
        id: _notificationId(i + 1, kind),
        title: '${content.titleMulti} (${usernames[i]})',
        body: content.body,
      );
    }
  }
}
