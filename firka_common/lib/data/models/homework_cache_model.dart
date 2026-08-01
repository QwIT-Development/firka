import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';

import 'package:kreta_api/kreta_api.dart';

part 'homework_cache_model.g.dart';

@collection
class HomeworkCacheModel extends GenericCacheModel<Homework> {
  late String teacherName;
  late DateTime dueDate;
  late DateTime startDate;
  late String description;
  bool isDone = false;

  final classGroup = IsarLink<ClassGroupCacheModel>();
  final subject = IsarLink<SubjectCacheModel>();

  @override
  void apply(CacheContext<Homework> ctx) {
    this
      ..teacherName = ctx.data.teacherName
      ..dueDate = ctx.data.dueDate
      ..startDate = ctx.data.startDate
      ..description = ctx.data.description
      ..createdAt = ctx.data.creationDate
      ..subject.init(ctx.cacheManager, ctx.data.subject)
      ..classGroup.unsafeInit(ctx.cacheManager, ctx.data.classGroup);

    if (subject.value == null) {
      isarInit.writeTxnSync(() {
        subject.value = SubjectCacheModel()
          ..cacheKey = ctx.cacheManager.genCacheKey(ctx.data.subject)
          ..name = ctx.data.subject.name
          ..createdAt = DateTime.now();
        isarInit.subjectCacheModels.putSync(subject.value!);
      });
    }
  }
}
