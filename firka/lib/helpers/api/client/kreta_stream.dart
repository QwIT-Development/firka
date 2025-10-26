import 'package:firka/helpers/api/model/class_group.dart';
import 'package:firka/helpers/api/model/homework.dart';
import 'package:firka/helpers/api/model/notice_board.dart';
import 'package:firka/helpers/api/model/omission.dart';
import 'package:firka/helpers/api/model/test.dart';
import 'package:firka/helpers/api/model/timetable.dart';

import '../model/grade.dart';
import '../model/student.dart';
import 'kreta_client.dart';

bool getStudentFL = false;
bool getClassGroupsFL = false;
bool getNoticeBoardStreamFL = false;
bool getInfoBoardStreamFL = false;
bool getGradesStreamFL = false;
bool getSubjectAverageStreamFL = false;
bool getHomeworkStreamFL = false;
bool getTimeTableStreamFL = false;
bool getTestsStreamFL = false;
bool getOmissionsStreamFL = false;

extension KretaStream on KretaClient {
  Stream<ApiResponse<Student>> getStudentStream(
      {bool cacheOnly = true}) async* {
    while (getStudentFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getStudentFL = true;
    yield await getStudent(forceCache: true);

    if (!cacheOnly) {
      yield await getStudent(forceCache: false);
    }
    getStudentFL = false;
  }

  Stream<ApiResponse<List<ClassGroup>>> getClassGroupsStream(
      {bool cacheOnly = true}) async* {
    while (getClassGroupsFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getClassGroupsFL = true;
    yield await getClassGroups(forceCache: true);

    if (!cacheOnly) {
      yield await getClassGroups(forceCache: false);
    }
    getClassGroupsFL = false;
  }

  Stream<ApiResponse<List<NoticeBoardItem>>> getNoticeBoardStream(
      {bool cacheOnly = true}) async* {
    while (getNoticeBoardStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getNoticeBoardStreamFL = true;
    yield await getNoticeBoard(forceCache: true);

    if (!cacheOnly) {
      yield await getNoticeBoard(forceCache: false);
    }
    getNoticeBoardStreamFL = false;
  }

  Stream<ApiResponse<List<InfoBoardItem>>> getInfoBoardStream(
      {bool cacheOnly = true}) async* {
    while (getInfoBoardStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getInfoBoardStreamFL = true;
    yield await getInfoBoard(forceCache: true);

    if (!cacheOnly) {
      yield await getInfoBoard(forceCache: false);
    }
    getInfoBoardStreamFL = false;
  }

  Stream<ApiResponse<List<Grade>>> getGradesStream(
      {bool cacheOnly = true}) async* {
    while (getGradesStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getGradesStreamFL = true;
    yield await getGrades(forceCache: true);

    if (!cacheOnly) {
      yield await getGrades(forceCache: false);
    }
    getGradesStreamFL = false;
  }

  Stream<ApiResponse<List<SubjectAverage>>> getSubjectAverageStream(
      ClassGroup classGroup,
      {bool cacheOnly = true}) async* {
    while (getSubjectAverageStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getSubjectAverageStreamFL = true;
    yield await getSubjectAverage(classGroup, forceCache: true);

    if (!cacheOnly) {
      yield await getSubjectAverage(classGroup, forceCache: false);
    }
    getSubjectAverageStreamFL = false;
  }

  Stream<ApiResponse<List<Homework>>> getHomeworkStream(
      {bool cacheOnly = true}) async* {
    while (getHomeworkStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getHomeworkStreamFL = true;
    yield await getHomework(forceCache: true);

    if (!cacheOnly) {
      yield await getHomework(forceCache: false);
    }
    getHomeworkStreamFL = false;
  }

  Stream<ApiResponse<List<Lesson>>> getTimeTableStream(
      DateTime from, DateTime to,
      {bool cacheOnly = true}) async* {
    while (getTimeTableStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getTimeTableStreamFL = true;
    yield await getTimeTable(from, to, forceCache: true);

    if (!cacheOnly) {
      yield await getTimeTable(from, to, forceCache: false);
    }
    getTimeTableStreamFL = false;
  }

  Stream<ApiResponse<List<Test>>> getTestsStream(
      {bool cacheOnly = true}) async* {
    while (getTestsStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getTestsStreamFL = true;
    yield await getTests(forceCache: true);

    if (!cacheOnly) {
      yield await getTests(forceCache: false);
    }
    getTestsStreamFL = false;
  }

  Stream<ApiResponse<List<Omission>>> getOmissionsStream(
      {bool cacheOnly = true}) async* {
    while (getOmissionsStreamFL) {
      await Future.delayed(Duration(milliseconds: 10));
    }
    getOmissionsStreamFL = true;
    yield await getOmissions(forceCache: true);

    if (!cacheOnly) {
      yield await getOmissions(forceCache: false);
    }
    getOmissionsStreamFL = false;
  }
}
