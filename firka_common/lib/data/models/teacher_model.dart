import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:isar_community/isar.dart';

part 'teacher_model.g.dart';

@collection
class TeacherModel {
  Id? id;
  late String name;
  late DateTime since;

  final classGroup = IsarLink<ClassGroupCacheModel>();
  final subject = IsarLink<SubjectCacheModel>();
}
