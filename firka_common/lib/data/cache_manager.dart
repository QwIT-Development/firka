import 'dart:collection';

import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/teacher_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

import 'models/token_model.dart';

typedef AfterQBFilter<OBJ> = QueryBuilder<OBJ, OBJ, QAfterFilterCondition>;
typedef QBFilter<OBJ> = QueryBuilder<OBJ, OBJ, QFilterCondition>;

class CacheManager {
  TokenModel token;

  CacheManager(this.token);

  StudentCacheModel findStudent() {
    return isarInit.studentCacheModels
        .filter()
        .group(isCurrentStudent)
        .findFirstSync()!;
  }

  int genCacheKey(Identifiable identifiable) {
    return _genCacheKey(identifiable.id);
  }

  int _genCacheKey(int id) {
    return id ^ token.iss.hashCode;
  }

  AfterQBFilter<StudentCacheModel> isCurrentStudent(
    QBFilter<StudentCacheModel> q,
  ) {
    return q.cacheKeyEqualTo(_genCacheKey(token.studentId));
  }

  AfterQBFilter<ClassGroupCacheModel> isCurrentClassGroup(
    QBFilter<ClassGroupCacheModel> q,
  ) {
    return q.student(isCurrentStudent);
  }

  AfterQBFilter<LessonCacheModel> getTimeTable() {
    return isarInit.lessonCacheModels.filter().classGroup(isCurrentClassGroup);
  }

  AfterQBFilter<LessonCacheModel> getClassLessons() {
    return getTimeTable().and().not().events();
  }

  AfterQBFilter<LessonCacheModel> getEvents() {
    return getTimeTable().and().events();
  }

  AfterQBFilter<GradeCacheModel> getGrades() {
    return isarInit.gradeCacheModels.filter().classGroup(isCurrentClassGroup);
  }

  AfterQBFilter<ClassAverageCacheModel> getClassAverages() {
    return isarInit.classAverageCacheModels.filter().student(isCurrentStudent);
  }

  AfterQBFilter<TestCacheModel> getTests() {
    return isarInit.testCacheModels.filter().lesson(
      (l) => l.classGroup(isCurrentClassGroup),
    );
  }

  AfterQBFilter<HomeworkCacheModel> getHomeworks() {
    return isarInit.homeworkCacheModels.filter().classGroup(
      isCurrentClassGroup,
    );
  }

  AfterQBFilter<MessageCacheModel> getMessages() {
    return isarInit.messageCacheModels.filter().student(isCurrentStudent);
  }

  AfterQBFilter<SubjectCacheModel> getSubjects() {
    return isarInit.subjectCacheModels.filter().teachers(
      (t) => t.classGroup(isCurrentClassGroup),
    );
  }

  AfterQBFilter<OmissionCacheModel> getOmissions() {
    return isarInit.omissionCacheModels.filter().lesson(
      (l) => l.classGroup(isCurrentClassGroup),
    );
  }

  void resolveTeachers() {
    Set<TeacherModel> teachers = HashSet<TeacherModel>(
      equals: (t, t2) =>
          t.name == t2.name &&
          t.subject.value!.cacheKey == t2.subject.value!.cacheKey &&
          t.classGroup.value!.cacheKey == t2.classGroup.value!.cacheKey,
      hashCode: (t) =>
          t.name.hashCode ^
          t.subject.value!.cacheKey ^
          t.classGroup.value!.cacheKey,
    );
    List<LessonCacheModel> lessons = getClassLessons()
        .sortByStart()
        .findAllSync();
    teachers.addAll(
      lessons.map(
        (l) => TeacherModel()
          ..name = l.teacher!
          ..since = l.start
          ..subject.value = l.subject.loadAndGet()!
          ..classGroup.value = l.classGroup.loadAndGet()!,
      ),
    );

    isarInit.writeTxnSync(() {
      isarInit.teacherModels.clearSync();
      isarInit.teacherModels.putAllSync(teachers.toList());
    });
  }
}
