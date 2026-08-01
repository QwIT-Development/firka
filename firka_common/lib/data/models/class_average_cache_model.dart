import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'class_average_cache_model.g.dart';

@collection
class ClassAverageCacheModel
    extends GenericCacheModel<ClassGroupSubjectAverage> {
  late float classAverage;
  late float studentAverage;

  final subject = IsarLink<SubjectCacheModel>();
  final student = IsarLink<StudentCacheModel>();

  @override
  void apply(CacheContext<ClassGroupSubjectAverage> ctx) {
    this
      ..classAverage = ctx.data.classGroupAverage as float
      ..studentAverage = ctx.data.studentAverage as float
      ..subject.init(ctx.cacheManager, ctx.data.subject)
      ..student.value = ctx.cacheManager.findStudent();
  }
}
