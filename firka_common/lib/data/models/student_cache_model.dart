import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'student_cache_model.g.dart';

@collection
class StudentCacheModel extends GenericCacheModel<Student> {
  late String name;
  late DateTime birthday;

  @override
  void apply(CacheContext<Student> ctx) {
    this
      ..name = ctx.data.name
      ..birthday = ctx.data.birthdate;
  }
}
