import 'package:isar_community/isar.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/data/util.dart';

part 'homework_cache_model.g.dart';

@collection
class HomeworkCacheModel extends DatedCacheEntry {
  HomeworkCacheModel();
}

Future<void> resetOldHomeworkCache(Isar isar) async {
  var now = timeNow();
  var weeks = await isar.homeworkCacheModels.where().findAll();
  var weeksToRemove = List<Id>.empty(growable: true);

  for (var week in weeks) {
    var date = getDate(week.cacheKey!);

    if (date.millisecondsSinceEpoch <
        now.subtract(Duration(days: 120)).millisecondsSinceEpoch) {
      weeksToRemove.add(week.cacheKey!);
    }
  }
  await isar.writeTxn(() async {
    await isar.homeworkCacheModels.deleteAll(weeksToRemove);
  });
}

@collection
class HomeworkDoneModel {
  Id? id;

  late String homeworkId;
  late DateTime doneAt;

  HomeworkDoneModel();
}

Future<void> markAsDone(Isar isar, String homeWorkUid) async {
  await isar.writeTxn(() async {
    await isar.homeworkDoneModels.put(
      HomeworkDoneModel()
        ..homeworkId = homeWorkUid
        ..doneAt = DateTime.now(),
    );
  });
}

Future<void> markAsNotDone(Isar isar, String homeWorkUid) async {
  await isar.writeTxn(() async {
    final idsToDelete = await isar.homeworkDoneModels
        .filter()
        .homeworkIdEqualTo(homeWorkUid)
        .idProperty()
        .findAll();
    await isar.homeworkDoneModels.deleteAll(idsToDelete);
  });
}

Future<bool> isHomeworkDone(Isar isar, String homeWorkUid) async {
  var existing = await isar.homeworkDoneModels
      .filter()
      .homeworkIdEqualTo(homeWorkUid)
      .findFirst();
  return existing != null;
}
