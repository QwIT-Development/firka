import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'api/model/timetable.dart';
import 'debug_helper.dart';

extension TimetableExtension on Iterable<Lesson> {
  List<Lesson> getAllSeqs(Lesson reference) {
    List<Lesson> lessons = List.empty(growable: true);

    for (var lesson in this) {
      if (lesson.lessonNumber == null) continue;

      if (lessons.firstWhereOrNull(
              (lesson2) => lesson.lessonNumber == lesson2.lessonNumber) ==
          null) {
        final ref = reference.start;
        final newStart = DateTime(ref.year, ref.month, ref.day,
            lesson.start.hour, lesson.start.minute, lesson.start.second);
        final newEnd = DateTime(ref.year, ref.month, ref.day, lesson.end.hour,
            lesson.end.minute, lesson.end.second);
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
            lastModifiedAt: lesson.lastModifiedAt);
        lessons.add(lessonCopy);
      }
    }

    lessons.sort((l1, l2) => l1.lessonNumber! - l2.lessonNumber!);

    return lessons;
  }
}

extension IterableExtensionMap on Iterable<MapEntry<String, dynamic>> {
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    for (var item in this) {
      map[item.key] = item.value;
    }

    return map;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension DurationExtension on Duration {
  String formatDuration() {
    String hours = inHours.toString().padLeft(2, '0');
    String minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }
}

enum FormatMode {
  yearly,
  grades,
  welcome,
  hmm,
  d,
  da,
  dd,
  yyyymmddwedd,
  yyyymmmm,
  yyyymmdd,
  yyyymmddhhmmss
}

enum Cycle { morning, day, afternoon, night }

extension DateExtension on DateTime {
  String format(AppLocalizations l10n, FormatMode mode) {
    var today = timeNow().getMidnight();

    var tomorrowLim = today.add(Duration(days: 2));
    var tomorrow = today.add(Duration(days: 1));
    var yesterday = today.subtract(Duration(days: 1));
    var yesterdayLim = today.subtract(Duration(days: 2));

    var weekStart = subtract(Duration(days: weekday - 1));
    var weekEnd = weekStart.add(Duration(days: 6));

    switch (mode) {
      case FormatMode.grades:
        if (isBefore(yesterdayLim)) {
          return format(l10n, FormatMode.yearly);
        }
        if (isAfter(yesterdayLim) && isBefore(today)) {
          return l10n.yesterday;
        }
        if (isAfter(yesterday) && isBefore(tomorrow)) {
          return l10n.today;
        }
        if (isAfter(today) && isBefore(tomorrowLim)) {
          return l10n.tomorrow;
        }

        return format(l10n, FormatMode.yearly);
      case FormatMode.yearly:
        return DateFormat('MMMM dd', l10n.localeName).format(this);
      case FormatMode.hmm:
        return DateFormat('H:mm', l10n.localeName).format(this);
      case FormatMode.welcome:
        return DateFormat('EEE, MMM d', l10n.localeName).format(this);
      case FormatMode.d:
        return DateFormat('d', l10n.localeName).format(this);
      case FormatMode.da:
        final s =
            DateFormat('EEEE', l10n.localeName).format(this).substring(0, 2);
        return s[0].toUpperCase() + s[1];
      case FormatMode.dd:
        return DateFormat('dd', l10n.localeName).format(this);
      case FormatMode.yyyymmddwedd:
        return "${DateFormat('yyyy MMM. dd', l10n.localeName).format(weekStart).toLowerCase()}-${DateFormat('dd', l10n.localeName).format(weekEnd)}";
      case FormatMode.yyyymmmm:
        return DateFormat('yyyy MMMM', l10n.localeName).format(this);
      case FormatMode.yyyymmdd:
        return DateFormat('yyyy. MM. dd.', l10n.localeName).format(this);
      case FormatMode.yyyymmddhhmmss:
        return DateFormat('yyyy-MM-dd hh:mm:ss', l10n.localeName).format(this);
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
    return subtract(Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond,
        microseconds: microsecond));
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

    var today = timeNow();
    today = today.subtract(Duration(
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));

    var tomorrow = today.add(Duration(days: 1));
    var yesterday = today.subtract(Duration(days: 1));

    for (var elem in this) {
      var date = getDate(elem);
      var day = date.subtract(Duration(
          hours: date.hour,
          minutes: date.minute,
          seconds: date.second,
          milliseconds: date.millisecond));

      if (date.isAfter(tomorrow.add(Duration(days: 1)))) {
        if (newList[day] == null) {
          newList[day] = List<T>.empty(growable: true);
        }

        newList[day]!.add(elem);
        continue;
      }
      if (date.isAfter(today)) {
        if (newList[tomorrow] == null) {
          newList[tomorrow] = List<T>.empty(growable: true);
        }

        newList[tomorrow]!.add(elem);
        continue;
      }
      if (date.isAfter(yesterday.subtract(Duration(days: 1))) &&
          date.isBefore(today)) {
        if (newList[yesterday] == null) {
          newList[yesterday] = List<T>.empty(growable: true);
        }

        newList[yesterday]!.add(elem);
        continue;
      }

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
        (lesson) => now.isAfter(lesson.start) && now.isBefore(lesson.end));
  }

  Lesson? getPrevLesson(DateTime now) {
    return firstWhereOrNull(
        (lesson) => lesson.end.isBefore(now.add(Duration(milliseconds: 1))));
  }

  Lesson? getNextLesson(DateTime now) {
    return firstWhereOrNull(
        (lesson) => lesson.start.isAfter(now.add(Duration(milliseconds: 1))));
  }
}
