import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

extension IterableExtension on Iterable<MapEntry<String, dynamic>> {
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    for (var item in this) {
      map[item.key] = item.value;
    }

    return map;
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

enum FormatMode { yearly, grades }

extension DateExtension on DateTime {
  String format(BuildContext context, FormatMode mode) {
    var today = DateTime.now();
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
      default:
        throw Exception("unimplemented format mode: $mode");
    }
  }
}

extension DateGrouper<T> on Iterable<T> {
  Map<DateTime, List<T>> groupList(DateTime Function(T elem) getDate) {
    Map<DateTime, List<T>> newList = {};

    var today = DateTime.now();
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
