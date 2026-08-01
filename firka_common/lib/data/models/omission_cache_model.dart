import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'omission_cache_model.g.dart';

@collection
class OmissionCacheModel extends GenericCacheModel<Omission> {
  int? lateMins;
  @Enumerated(EnumType.name)
  late OmissionState state;
  late String teacherName;
  String? proofType;

  final lesson = IsarLink<LessonCacheModel>();

  @override
  void apply(CacheContext<Omission> ctx) {
    this
      ..lateMins = ctx.data.lateForMin
      ..state = ctx.data.state
      ..teacherName = ctx.data.teacher
      ..proofType = ctx.data.proofType?.description
      ..createdAt = ctx.data.createdAt;
    lesson.value = ctx.cacheManager
        .getTimeTable()
        .startEqualTo(ctx.data.lesson!.start)
        .and()
        .endEqualTo(ctx.data.lesson!.end)
        .findFirstSync();
  }
}
