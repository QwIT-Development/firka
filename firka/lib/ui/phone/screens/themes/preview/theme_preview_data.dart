import "package:firka_common/core/debug_helper.dart";
import "package:firka_common/data/models/grade_cache_model.dart";
import "package:firka_common/data/models/lesson_cache_model.dart";
import "package:firka_common/data/models/message_cache_model.dart";
import "package:firka_common/data/models/omission_cache_model.dart";
import "package:firka_common/data/models/student_cache_model.dart";
import "package:firka_common/data/models/subject_cache_model.dart";
import "package:firka_common/data/models/test_cache_model.dart";
import "package:kreta_api/kreta_api.dart";

/// In-memory placeholder models for theme page previews (Figma sample content).
class ThemePreviewData {
  ThemePreviewData._({
    required this.now,
    required this.student,
    required this.subjects,
    required this.homeLessons,
    required this.timetableLessons,
    required this.messages,
    required this.tests,
    required this.grades,
    required this.chartGrades,
    required this.omissions,
    required this.omissionBarSegments,
    required this.omissionExcusedCount,
    required this.omissionPendingCount,
    required this.omissionUnexcusedCount,
    required this.monthDayMeta,
    required this.subjectDetailSubject,
    required this.subjectDetailGrades,
    required this.subjectDetailTeacher,
  });

  final DateTime now;
  final StudentCacheModel student;
  final List<SubjectCacheModel> subjects;
  final List<LessonCacheModel> homeLessons;
  final List<LessonCacheModel> timetableLessons;
  final List<MessageCacheModel> messages;
  final List<TestCacheModel> tests;
  final List<GradeCacheModel> grades;
  final List<GradeCacheModel> chartGrades;
  final List<OmissionCacheModel> omissions;
  final List<OmissionState?> omissionBarSegments;
  final int omissionExcusedCount;
  final int omissionPendingCount;
  final int omissionUnexcusedCount;
  final Map<DateTime, ThemePreviewMonthDay> monthDayMeta;
  final SubjectCacheModel subjectDetailSubject;
  final List<GradeCacheModel> subjectDetailGrades;
  final String subjectDetailTeacher;

  SubjectCacheModel get matematika => subjects[0];
  SubjectCacheModel get angol => subjects[1];
  SubjectCacheModel get tortenelem => subjects[2];
  SubjectCacheModel get nemet => subjects[3];
  SubjectCacheModel get informatika => subjects[4];
  SubjectCacheModel get fizika => subjects[5];

  static ThemePreviewData build([DateTime? clock]) {
    final now = clock ?? timeNow();
    // Anchor to real time so LessonSlider / LessonBigWidget (which call
    // timeNow()) keep Matematika as the active lesson with ~35 min left.
    final midnight = DateTime(now.year, now.month, now.day);
    final day = now;

    final subjects = [
      _subject(1, "Matematika"),
      _subject(2, "Angol nyelv"),
      _subject(3, "Történelem"),
      _subject(4, "Német"),
      _subject(5, "Informatika"),
      _subject(6, "Fizika"),
    ];
    final matematika = subjects[0];
    final angol = subjects[1];
    final tortenelem = subjects[2];
    final nemet = subjects[3];
    final informatika = subjects[4];
    final fizika = subjects[5];

    final student = StudentCacheModel()
      ..cacheKey = 1
      ..createdAt = midnight
      ..name = "Kovács Ádám"
      ..birthday = DateTime(2008, 3, 15);

    // Active lesson: started 10 min ago, ends in 34 min => "35 perc" via timeLeft.
    final homeLessons = [
      _lesson(
        id: 101,
        subject: matematika,
        dailyNth: 1,
        start: now.subtract(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 34)),
        roomName: "123",
      ),
      _lesson(
        id: 102,
        subject: angol,
        dailyNth: 2,
        start: now.add(const Duration(minutes: 45)),
        end: now.add(const Duration(minutes: 90)),
        roomName: "123",
      ),
      _lesson(
        id: 103,
        subject: tortenelem,
        dailyNth: 3,
        start: now.add(const Duration(minutes: 100)),
        end: now.add(const Duration(minutes: 145)),
        roomName: "201",
      ),
    ];

    final testLektion = TestCacheModel()
      ..cacheKey = 201
      ..createdAt = midnight
      ..topic = "Lektion 14"
      ..method = "Írásbeli"
      ..teacherName = "Müller Anna";

    final testBinaris = TestCacheModel()
      ..cacheKey = 202
      ..createdAt = midnight
      ..topic = "Bináris fák"
      ..method = "Írásbeli"
      ..teacherName = "Nagy Péter";

    final ttBase = DateTime(day.year, day.month, day.day, 8, 0);
    final timetableLessons = [
      _lesson(
        id: 301,
        subject: nemet,
        dailyNth: 1,
        start: ttBase,
        end: ttBase.add(const Duration(minutes: 45)),
        roomName: "12",
        substituteTeacher: "Kiss Éva",
      ),
      _lesson(
        id: 302,
        subject: matematika,
        dailyNth: 2,
        start: ttBase.add(const Duration(minutes: 55)),
        end: ttBase.add(const Duration(minutes: 100)),
        roomName: "123",
        type: "UresOra",
        test: testLektion,
      ),
      _lesson(
        id: 303,
        subject: matematika,
        dailyNth: 3,
        start: ttBase.add(const Duration(minutes: 110)),
        end: ttBase.add(const Duration(minutes: 155)),
        roomName: "123",
      ),
      _lesson(
        id: 304,
        subject: informatika,
        dailyNth: 4,
        start: ttBase.add(const Duration(minutes: 165)),
        end: ttBase.add(const Duration(minutes: 210)),
        roomName: "Inf1",
        test: testBinaris,
      ),
      _lesson(
        id: 305,
        subject: informatika,
        dailyNth: 5,
        start: ttBase.add(const Duration(minutes: 220)),
        end: ttBase.add(const Duration(minutes: 265)),
        roomName: "Inf1",
      ),
    ];

    final homeTest = TestCacheModel()
      ..cacheKey = 203
      ..createdAt = midnight.subtract(const Duration(days: 1))
      ..topic = "Függvények"
      ..method = "Írásbeli"
      ..teacherName = "Szabó Gábor";
    homeTest.lesson.value = homeLessons[0];

    final messages = [
      MessageCacheModel()
        ..cacheKey = 401
        ..createdAt = midnight.subtract(const Duration(days: 2))
        ..author = "Pálfy Zoltán"
        ..title = "2023 novemberi programok"
        ..contentHtml = "",
      MessageCacheModel()
        ..cacheKey = 402
        ..createdAt = midnight.subtract(const Duration(days: 2))
        ..author = ":3"
        ..title = "Mrrp mrrp meow meow"
        ..contentHtml = "",
    ];

    final grades = [
      _grade(501, matematika, 5, midnight.subtract(const Duration(days: 3))),
      _grade(502, matematika, 4, midnight.subtract(const Duration(days: 10))),
      _grade(503, angol, 5, midnight.subtract(const Duration(days: 4))),
      _grade(504, angol, 3, midnight.subtract(const Duration(days: 12))),
      _grade(505, tortenelem, 4, midnight.subtract(const Duration(days: 5))),
      _grade(506, nemet, 5, midnight.subtract(const Duration(days: 6))),
      _grade(507, informatika, 5, midnight.subtract(const Duration(days: 7))),
      _grade(508, fizika, 4, midnight.subtract(const Duration(days: 8))),
      _grade(509, matematika, 5, midnight.subtract(const Duration(days: 15))),
    ];

    final sept = DateTime(
      day.month >= DateTime.september ? day.year : day.year - 1,
      DateTime.september,
      15,
    );
    final chartSpanDays = day.difference(sept).inDays.clamp(1, 365);
    const chartValues = [
      1, 1, 1, 1, 2, 2, 2, 2, 2, 2,
      3, 3, 3, 3, 3, 3, 3, 4, 4, 4,
      4, 4, 3, 3, 4, 4, 4, 4, 5, 5,
      5, 4, 4, 5, 5, 5, 5, 5, 5, 5,
      5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    ];
    final chartGrades = [
      for (var i = 0; i < chartValues.length; i++)
        _grade(
          700 + i,
          matematika,
          chartValues[i],
          sept.add(
            Duration(days: (i * chartSpanDays / (chartValues.length - 1)).round()),
          ),
        ),
    ];

    final omissions = [
      _omission(
        601,
        homeLessons[1],
        OmissionState.excused,
        midnight.subtract(const Duration(days: 20)),
      ),
      _omission(
        602,
        homeLessons[2],
        OmissionState.pending,
        midnight.subtract(const Duration(days: 14)),
      ),
      _omission(
        603,
        timetableLessons[0],
        OmissionState.unexcused,
        midnight.subtract(const Duration(days: 9)),
      ),
      _omission(
        604,
        timetableLessons[3],
        OmissionState.excused,
        midnight.subtract(const Duration(days: 3)),
      ),
    ];

    // School-year style bar: mostly present days, sparse marks, a few clusters
    // for thicker ticks (matches the design "barcode" look).
    final omissionBarSegments = List<OmissionState?>.filled(132, null);
    const excusedClusters = <List<int>>[
      [2],
      [7, 8],
      [14],
      [19],
      [24, 25, 26],
      [33],
      [38],
      [44, 45],
      [52],
      [58],
      [64, 65],
      [71],
      [77],
      [83, 84, 85],
      [92],
      [104, 105],
      [112],
      [118],
      [124, 125],
    ];
    for (final cluster in excusedClusters) {
      for (final i in cluster) {
        omissionBarSegments[i] = OmissionState.excused;
      }
    }
    // Pending (orange) ticks, including a short cluster.
    for (final i in [16, 48, 49, 88, 110]) {
      omissionBarSegments[i] = OmissionState.pending;
    }
    // Unexcused (red/pink) ticks.
    for (final i in [61, 96, 127]) {
      omissionBarSegments[i] = OmissionState.unexcused;
    }

    final monthStart = DateTime(day.year, day.month, 1);
    final gridStart = monthStart
        .subtract(Duration(days: monthStart.weekday - 1))
        .subtract(const Duration(days: 7));
    final monthDayMeta = <DateTime, ThemePreviewMonthDay>{};
    for (var i = 0; i < 49; i++) {
      final d = DateTime(
        gridStart.year,
        gridStart.month,
        gridStart.day,
      ).add(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day);
      final inMonth = d.month == day.month;
      final weekday = d.weekday;
      final lessonCount = !inMonth
          ? 0
          : weekday > 5
          ? 0
          : 5 - ((d.day + weekday) % 3);
      OmissionState? omission;
      if (inMonth && weekday <= 5 && d.day % 9 == 0) {
        omission = OmissionState.pending;
      } else if (inMonth && weekday <= 5 && d.day % 13 == 0) {
        omission = OmissionState.unexcused;
      }
      monthDayMeta[key] = ThemePreviewMonthDay(
        lessonCount: lessonCount.clamp(0, 7),
        hasTest: inMonth && weekday <= 5 && d.day % 7 == 0,
        omission: omission,
      );
    }

    final subjectDetailGrades = grades
        .where((g) => g.subject.value?.cacheKey == matematika.cacheKey)
        .toList();

    return ThemePreviewData._(
      now: day,
      student: student,
      subjects: subjects,
      homeLessons: homeLessons,
      timetableLessons: timetableLessons,
      messages: messages,
      tests: [homeTest],
      grades: grades,
      chartGrades: chartGrades,
      omissions: omissions,
      omissionBarSegments: omissionBarSegments,
      omissionExcusedCount: 2,
      omissionPendingCount: 1,
      omissionUnexcusedCount: 1,
      monthDayMeta: monthDayMeta,
      subjectDetailSubject: matematika,
      subjectDetailGrades: subjectDetailGrades,
      subjectDetailTeacher: "Szabó Gábor (Osztály)",
    );
  }

  static SubjectCacheModel _subject(int id, String name) {
    final subject = SubjectCacheModel()
      ..cacheKey = id
      ..createdAt = DateTime(2024, 9, 1)
      ..name = name;
    subject.classAverage.value = null;
    return subject;
  }

  static LessonCacheModel _lesson({
    required int id,
    required SubjectCacheModel subject,
    required int dailyNth,
    required DateTime start,
    required DateTime end,
    required String roomName,
    String? substituteTeacher,
    String type = "OrarendiOra",
    TestCacheModel? test,
  }) {
    final lesson = LessonCacheModel()
      ..cacheKey = id
      ..createdAt = start
      ..start = start
      ..end = end
      ..dailyNth = dailyNth
      ..yearlyNth = dailyNth
      ..name = subject.name
      ..roomName = roomName
      ..state = "Naplozott"
      ..type = type
      ..teacher = "Tanár"
      ..substituteTeacher = substituteTeacher;
    lesson.subject.value = subject;
    // Mark optional links loaded so loadAndGet() does not call loadSync on
    // unmanaged (non-Isar) preview objects.
    lesson.test.value = test;
    lesson.homework.value = null;
    lesson.classGroup.value = null;
    lesson.omission.value = null;
    if (test != null) {
      test.lesson.value = lesson;
    }
    return lesson;
  }

  static GradeCacheModel _grade(
    int id,
    SubjectCacheModel subject,
    int value,
    DateTime at, {
    int? weightPercentage = 100,
  }) {
    final grade = GradeCacheModel()
      ..cacheKey = id
      ..createdAt = at
      ..mode = "Írásbeli"
      ..topic = subject.name
      ..type = "Értékelés"
      ..valueType = "Osztalyzat"
      ..writtenAt = at
      ..numericValue = value
      ..weightPercentage = weightPercentage
      ..textValue = value.toString()
      ..teacherName = "Tanár";
    grade.subject.value = subject;
    grade.classGroup.value = null;
    return grade;
  }

  static OmissionCacheModel _omission(
    int id,
    LessonCacheModel lesson,
    OmissionState state,
    DateTime at,
  ) {
    final omission = OmissionCacheModel()
      ..cacheKey = id
      ..createdAt = at
      ..state = state
      ..teacherName = "Tanár";
    omission.lesson.value = lesson;
    return omission;
  }
}

class ThemePreviewMonthDay {
  const ThemePreviewMonthDay({
    required this.lessonCount,
    required this.hasTest,
    this.omission,
  });

  final int lessonCount;
  final bool hasTest;
  final OmissionState? omission;
}
