import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/teacher_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'subject_cache_model.g.dart';

@collection
class SubjectCacheModel extends GenericCacheModel<DktSubject> {
  late String name;

  @Backlink(to: "subject")
  final classAverage = IsarLink<ClassAverageCacheModel>();

  @Backlink(to: "subject")
  final teachers = IsarLinks<TeacherModel>();

  @override
  void apply(CacheContext<DktSubject> ctx) {
    this..name = ctx.data.name;
  }
}
