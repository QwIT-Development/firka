import 'package:firka_common/core/consts.dart';
import 'package:firka_common/core/extensions.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'lesson_cache_model.g.dart';

@collection
class LessonCacheModel extends GenericCacheModel<Lesson> {
  @Index()
  late DateTime start;
  late DateTime end;
  int? dailyNth; // null = event
  int? yearlyNth; // null = event
  late String name;
  String? topic;
  String? roomName; // null = event
  late String state;
  late String type;
  String? teacher;
  String? substituteTeacher;

  final homework = IsarLink<HomeworkCacheModel>();
  final subject = IsarLink<SubjectCacheModel>(); // null = event
  final test = IsarLink<TestCacheModel>();
  final classGroup = IsarLink<ClassGroupCacheModel>(); // null = whole class

  @Backlink(to: "lesson")
  final omission = IsarLink<OmissionCacheModel>();

  @override
  void apply(CacheContext<Lesson> ctx) {
    this
      ..start = ctx.data.start
      ..end = ctx.data.end
      ..dailyNth = ctx.data.lessonNumber
      ..yearlyNth = ctx.data.lessonSeqNumber
      ..state = ctx.data.state.name
      ..teacher = ctx.data.teacher
      ..substituteTeacher = ctx.data.substituteTeacher
      ..name = ctx.data.name
      ..topic = ctx.data.theme
      ..roomName = ctx.data.roomName
      ..type = ctx.data.type.name
      ..classGroup.init(ctx.cacheManager, ctx.data.classGroup)
      ..subject.init(ctx.cacheManager, ctx.data.subject);

    if (subject.value == null && ctx.data.subject != null) {
      isarInit.writeTxnSync(() {
        subject.value = SubjectCacheModel()
          ..cacheKey = ctx.cacheManager.genCacheKey(ctx.data.subject!)
          ..name = ctx.data.subject!.name
          ..createdAt = DateTime.now();
        isarInit.subjectCacheModels.putSync(subject.value!);
      });
    }

    if (ctx.data.assessmentUid != null) {
      test.init(ctx.cacheManager, UidObj(uid: ctx.data.assessmentUid!));
    }

    if (ctx.data.homeworkUid != null) {
      homework.init(ctx.cacheManager, UidObj(uid: ctx.data.homeworkUid!));
    }

    if (classGroup.value == null) {
      classGroup.value = isarInit.classGroupCacheModels
          .filter()
          .group(ctx.cacheManager.isCurrentClassGroup)
          .and()
          .typeEqualTo("Osztaly")
          .findFirstSync()!;
    }
  }

  bool isEvent() {
    return type == TimetableConsts.event;
  }
}

typedef AfterQBFilter<OBJ> = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>;
typedef QBFilter<OBJ> = QueryBuilder<OBJ, OBJ, QFilterCondition>;

extension LessonFilterExtension on QBFilter<LessonCacheModel> {
  AfterQBFilter<LessonCacheModel> events() {
    return typeEqualTo(TimetableConsts.event);
  }

  AfterQBFilter<LessonCacheModel> between(DateTime fromDate, DateTime toDate) {
    return startBetween(
      fromDate.getMidnight(),
      toDate.getMidnight().add(Duration(days: 1)),
      includeUpper: false,
    );
  }

  AfterQBFilter<LessonCacheModel> on(DateTime date) {
    return between(date, date);
  }
}
