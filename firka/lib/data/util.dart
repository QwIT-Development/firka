import 'dart:math';

import 'package:isar_community/isar.dart';

import 'package:firka/core/debug_helper.dart';

class DatedCacheEntry {
  Id? cacheKey;
  late List<String> values;
}

int genCacheKey(DateTime date, int studentId) {
  var md = date.month * pow(10, 2) + date.day;

  return (md * pow(10, 11) + studentId) as int;
}

DateTime getDate(int key) {
  var md = key ~/ pow(10, 11);
  var month = md ~/ pow(10, 2);
  var day = (md - month * pow(10, 2)) as int;

  return DateTime(timeNow().year, month, day);
}
