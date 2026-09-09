import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'test_cache_model.g.dart';

@collection
class TestCacheModel extends GenericCacheModel<Test> {
  late String? topic;
  late String method;
  late String teacherName;

  @Backlink(to: "test")
  final lesson = IsarLink<LessonCacheModel>();
  final classGroup = IsarLink<ClassGroupCacheModel>();

  @override
  void apply(CacheContext<Test> ctx) {
    this
      ..topic = ctx.data.theme
      ..method = ctx.data.method.description
      ..teacherName = ctx.data.teacherName
      ..createdAt = ctx.data.reportDate
      ..classGroup.unsafeInit(ctx.cacheManager, ctx.data.classGroup);
  }
}
