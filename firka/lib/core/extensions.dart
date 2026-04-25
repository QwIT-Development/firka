import 'package:intl/intl.dart';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka_common/core/debug_helper.dart';
import 'package:firka_common/core/extensions.dart';
import 'package:kreta_api/kreta_api.dart';

export 'package:firka_common/core/extensions.dart';

extension TimetableExtension on Iterable<Lesson> {
  List<Lesson> getAllSeqs(Lesson reference) {
    List<Lesson> lessons = List.empty(growable: true);

    for (var lesson in this) {
      if (lesson.lessonNumber == null) continue;

      if (!lessons.any(
        (lesson2) => lesson.lessonNumber == lesson2.lessonNumber,
      )) {
        final ref = reference.start;
        final newStart = DateTime(
          ref.year,
          ref.month,
          ref.day,
          lesson.start.hour,
          lesson.start.minute,
          lesson.start.second,
        );
        final newEnd = DateTime(
          ref.year,
          ref.month,
          ref.day,
          lesson.end.hour,
          lesson.end.minute,
          lesson.end.second,
        );
        final lessonCopy = Lesson(
          uid: lesson.uid,
          date: lesson.date,
          start: newStart,
          end: newEnd,
          name: lesson.name,
          type: lesson.type,
          state: lesson.state,
          canStudentEditHomework: lesson.canStudentEditHomework,
          isHomeworkComplete: lesson.isHomeworkComplete,
          attachments: lesson.attachments,
          lessonNumber: lesson.lessonNumber,
          isDigitalLesson: lesson.isDigitalLesson,
          digitalSupportDeviceTypeList: lesson.digitalSupportDeviceTypeList,
          createdAt: lesson.createdAt,
          lastModifiedAt: lesson.lastModifiedAt,
        );
        lessons.add(lessonCopy);
      }
    }

    lessons.sort((l1, l2) => l1.lessonNumber! - l2.lessonNumber!);

    return lessons;
  }
}

extension DurationExtension on Duration {
  String formatDuration() {
    String hours = inHours.toString().padLeft(2, '0');
    String minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  String timeLeft(AppLocalizations l10n) {
    return inMinutes > 1
        ? "$inMinutes ${inMinutes == 1 ? l10n.starting_min : l10n.starting_min_plural}"
        : inSeconds > 0
        ? "$inSeconds ${inSeconds == 1 ? l10n.starting_sec : l10n.starting_sec_plural}"
        : "- ${l10n.starting_sec}";
  }
}

enum FormatMode {
  yearly,
  mmmd,
  main,
  grades,
  welcome,
  hmm,
  d,
  da,
  dd,
  yyyymmddwedd,
  yyyymmmm,
  yyyymmdd,
  yyyymmddhhmmss,
}

enum Cycle { morning, day, afternoon, night }

extension ComparableExtension<T extends Comparable<T>> on Comparable<T> {
  T min(T other) {
    return compareTo(other) < 0 ? this as T : other;
  }

  bool isBetween(T from, T to) {
    return compareTo(from) > 0 && compareTo(to) < 0;
  }

  T max(T other) {
    return compareTo(other) > 0 ? this as T : other;
  }
}

extension DateExtension on DateTime {
  String? translatedDay(AppLocalizations l10n) {
    var today = timeNow().getMidnight();

    var tomorrowLim = today.add(Duration(days: 2));
    var tomorrow = today.add(Duration(days: 1));
    var yesterday = today.subtract(Duration(days: 1));
    var yesterdayLim = today.subtract(Duration(days: 2));

    if (isAfter(yesterdayLim) && isBefore(today)) {
      return l10n.yesterday;
    }
    if (isAfter(yesterday) && isBefore(tomorrow)) {
      return l10n.today;
    }
    if (isAfter(today) && isBefore(tomorrowLim)) {
      return l10n.tomorrow;
    }

    return null;
  }

  String format(AppLocalizations l10n, FormatMode mode) {
    var weekStart = getMonday();
    var weekEnd = weekStart.add(Duration(days: 6));

    switch (mode) {
      case FormatMode.main:
        var lastWeek = timeNow().getMidnight().subtract(Duration(days: 8));
        var isLastWeek =
            lastWeek.millisecondsSinceEpoch <
            getMidnight().millisecondsSinceEpoch;
        final dayName = DateFormat(
          'EEEE',
          l10n.localeName,
        ).format(this).firstUpper();
        return translatedDay(l10n) ??
            (isLastWeek
                ? "$dayName (${format(l10n, FormatMode.mmmd).firstUpper()})"
                : "${format(l10n, FormatMode.yearly).firstUpper()} ($dayName)");
      case FormatMode.grades:
        return translatedDay(l10n) ?? format(l10n, FormatMode.yearly);
      case FormatMode.yearly:
        return DateFormat('MMMM d', l10n.localeName).format(this);
      case FormatMode.mmmd:
        return DateFormat('MMM d', l10n.localeName).format(this);
      case FormatMode.hmm:
        return DateFormat('H:mm', l10n.localeName).format(this);
      case FormatMode.welcome:
        final dayName = DateFormat(
          'EEEE',
          l10n.localeName,
        ).format(this).firstUpper();
        final monthAbbr = DateFormat(
          'MMM',
          l10n.localeName,
        ).format(this).firstUpper();
        final day = DateFormat('d', l10n.localeName).format(this);
        return "$dayName, $monthAbbr $day";
      case FormatMode.d:
        return DateFormat('d', l10n.localeName).format(this);
      case FormatMode.da:
        return DateFormat(
          'EEEE',
          l10n.localeName,
        ).format(this).substring(0, 2).firstUpper();
      case FormatMode.dd:
        return DateFormat('dd', l10n.localeName).format(this);
      case FormatMode.yyyymmddwedd:
        if (l10n.localeName == "en") {
          return "${DateFormat('yyyy MMM. dd', l10n.localeName).format(weekStart).toLowerCase()}-${DateFormat('dd', l10n.localeName).format(weekEnd)}";
        } else {
          return "${DateFormat('yyyy MMM dd', l10n.localeName).format(weekStart).toLowerCase()}-${DateFormat('dd', l10n.localeName).format(weekEnd)}";
        }
      case FormatMode.yyyymmmm:
        return DateFormat('yyyy MMMM', l10n.localeName).format(this);
      case FormatMode.yyyymmdd:
        return DateFormat('yyyy. MM. dd.', l10n.localeName).format(this);
      case FormatMode.yyyymmddhhmmss:
        return DateFormat(
          'yyyy. MM. dd. H:mm:ss',
          l10n.localeName,
        ).format(this);
    }
  }

  int weekNumber() {
    int dayOfYear = int.parse(DateFormat("D").format(this));
    return ((dayOfYear - weekday + 10) / 7).floor();
  }

  bool isAWeek() {
    return weekNumber() % 2 == 0;
  }

  DateTime getMonday() {
    return subtract(Duration(days: weekday - 1));
  }

  DateTime getMidnight() {
    return subtract(
      Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond,
        microseconds: microsecond,
      ),
    );
  }

  Cycle getDayCycle() {
    var midnight = getMidnight();
    if (isAfter(midnight.add(Duration(hours: 5, minutes: 30))) &&
        isBefore(midnight.add(Duration(hours: 9)))) {
      return Cycle.morning;
    }
    if (isAfter(midnight.add(Duration(hours: 5, minutes: 30))) &&
        isBefore(midnight.add(Duration(hours: 14)))) {
      return Cycle.day;
    }
    if (isAfter(midnight.add(Duration(hours: 5, minutes: 30))) &&
        isBefore(midnight.add(Duration(hours: 18)))) {
      return Cycle.afternoon;
    }

    return Cycle.night;
  }
}

extension DateGrouper<T> on Iterable<T> {
  Map<DateTime, List<T>> groupList(DateTime Function(T elem) getDate) {
    Map<DateTime, List<T>> newList = {};

    for (var elem in this) {
      var date = getDate(elem);
      var day = date.getMidnight();

      if (newList[day] == null) {
        newList[day] = List<T>.empty(growable: true);
      }

      newList[day]!.add(elem);
    }

    return newList;
  }
}

extension LessonExtension on List<Lesson> {
  int getLessonNo(Lesson lesson) {
    return lesson.lessonNumber ?? indexOf(lesson);
  }

  Lesson? getCurrentLesson(DateTime now) {
    return firstWhereOrNull(
      (lesson) => now.isAfter(lesson.start) && now.isBefore(lesson.end),
    );
  }

  Lesson? getPrevLesson(DateTime now) {
    return reversed.firstWhereOrNull(
      (lesson) => lesson.end.isBefore(now.add(Duration(milliseconds: 1))),
    );
  }

  Lesson? getNextLesson(DateTime now) {
    return firstWhereOrNull(
      (lesson) => lesson.start.isAfter(now.add(Duration(milliseconds: 1))),
    );
  }
}

extension StringExtension on String {
  bool isNumeric() {
    final regex = RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$');
    return regex.hasMatch(trim());
  }

  String firstUpper() {
    if (isEmpty) return this;
    if (length == 1) this[0].toUpperCase();
    return this[0].toUpperCase() + substring(1, length);
  }
}
