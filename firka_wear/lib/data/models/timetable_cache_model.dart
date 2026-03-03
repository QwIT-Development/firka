import 'package:isar_community/isar.dart';

import 'package:firka_wear/core/debug_helper.dart';
import 'package:firka_wear/data/util.dart';

part 'timetable_cache_model.g.dart';

@collection
class TimetableCacheModel extends DatedCacheEntry {
  TimetableCacheModel();
}

Future<void> resetOldTimeTableCache(Isar isar) async {
  var now = timeNow();
  var weeks = await isar.timetableCacheModels.where().findAll();
  var weeksToRemove = List<Id>.empty(growable: true);

  for (var week in weeks) {
    var date = getDate(week.cacheKey!);

    if (date.millisecondsSinceEpoch <
        now.subtract(const Duration(days: 30)).millisecondsSinceEpoch) {
      weeksToRemove.add(week.cacheKey!);
    }
  }
  await isar.writeTxn(() async {
    await isar.timetableCacheModels.deleteAll(weeksToRemove);
  });
}
