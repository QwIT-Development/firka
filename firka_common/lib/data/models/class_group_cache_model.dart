import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'class_group_cache_model.g.dart';

@collection
class ClassGroupCacheModel extends GenericCacheModel<ClassGroup> {
  late String name;
  late bool isActive;
  late String type;
  late String educationalOrderUid;
  late String educationalOrderName;
  late String educationalOrderDescription;

  final student = IsarLink<StudentCacheModel>();

  @override
  void apply(CacheContext<ClassGroup> ctx) {
    this
      ..name = ctx.data.name
      ..isActive = ctx.data.isActive
      ..type = ctx.data.type
      ..educationalOrderUid = ctx.data.studyTask!.uid
      ..educationalOrderName = ctx.data.studyTask!.name
      ..educationalOrderDescription = ctx.data.studyTask!.description
      ..student.value = ctx.cacheManager.findStudent();
  }
}
