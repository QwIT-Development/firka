import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'grade_cache_model.g.dart';

@collection
class GradeCacheModel extends GenericCacheModel<Grade> {
  String? mode;
  String? topic;
  late String type;
  late String valueType;
  late DateTime writtenAt;
  int? numericValue;
  int? weightPercentage;
  late String textValue;
  late String teacherName;

  final classGroup = IsarLink<ClassGroupCacheModel>();
  final subject = IsarLink<SubjectCacheModel>();

  @override
  void apply(CacheContext<Grade> ctx) {
    this
      ..mode = ctx.data.mode?.description
      ..topic = ctx.data.topic
      ..type = ctx.data.type.description
      ..valueType = ctx.data.valueType.name
      ..writtenAt = ctx.data.recordDate
      ..numericValue = ctx.data.numericValue
      ..weightPercentage = ctx.data.weightPercentage
      ..textValue = ctx.data.strValue
      ..teacherName = ctx.data.teacher
      ..createdAt = ctx.data.creationDate
      ..classGroup.unsafeInit(ctx.cacheManager, ctx.data.classGroup)
      ..subject.init(ctx.cacheManager, ctx.data.subject);

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
