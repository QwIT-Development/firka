import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'api/model/timetable.dart';
import 'debug_helper.dart';

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

enum FormatMode { yearly, grades, welcome, hmm, da, dd }

enum Cycle { morning, day, afternoon, night }

extension DateExtension on DateTime {
  String format(BuildContext context, FormatMode mode) {
    var today = timeNow();
    today = today.subtract(Duration(
        hours: today.hour,
        minutes: today.minute,
        seconds: today.second,
        milliseconds: today.millisecond));

    var tomorrowLim = today.add(Duration(days: 2));
    var tomorrow = today.add(Duration(days: 1));
    var yesterday = today.subtract(Duration(days: 1));
    var yesterdayLim = today.subtract(Duration(days: 2));

    switch (mode) {
      case FormatMode.grades:
        if (isBefore(yesterdayLim)) {
          return format(context, FormatMode.yearly);
        }
        if (isAfter(yesterdayLim) && isBefore(today)) {
          return AppLocalizations.of(context)!.yesterday;
        }
        if (isAfter(yesterday) && isBefore(tomorrow)) {
          return AppLocalizations.of(context)!.today;
        }
        if (isAfter(today) && isBefore(tomorrowLim)) {
          return AppLocalizations.of(context)!.tomorrow;
        }

        return format(context, FormatMode.yearly);
      case FormatMode.yearly:
        return DateFormat('MMMM dd').format(this);
      case FormatMode.hmm:
        return DateFormat('H:mm').format(this);
      case FormatMode.welcome:
        return DateFormat('EEE, MMM d').format(this);
      case FormatMode.da:
        return DateFormat('MMMMEEEEd').format(this).substring(0, 2);
      case FormatMode.dd:
        return DateFormat('dd').format(this);
    }
  }

  DateTime getMonday() {
    return subtract(Duration(days: weekday - 1));
  }

  DateTime getMidnight() {
    return subtract(Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: millisecond));
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
        isBefore(midnight.add(Duration(hours: 20)))) {
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
