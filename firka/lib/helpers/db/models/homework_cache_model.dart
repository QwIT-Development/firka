import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:isar/isar.dart';

import '../util.dart';

part 'homework_cache_model.g.dart';

@collection
class HomeworkCacheModel extends DatedCacheEntry {
  HomeworkCacheModel();
}

Future<void> resetOldHomeworkCache(Isar isar) async {
  var now = DateTime.now();
  var weeks = await isar.homeworkCacheModels.where().findAll();
  var weeksToRemove = List<Id>.empty(growable: true);

  for (var week in weeks) {
    var date = getDate(week.cacheKey!);

    if (date.millisecondsSinceEpoch <
        now.subtract(Duration(days: 30)).millisecondsSinceEpoch) {
      weeksToRemove.add(week.cacheKey!);
    }
  }
  await isar.writeTxn(() async {
    await isar.homeworkCacheModels.deleteAll(weeksToRemove);
  });
}
