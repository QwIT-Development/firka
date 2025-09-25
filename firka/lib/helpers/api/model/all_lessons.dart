import 'dart:convert';

class AllLessons {
  final String schoolId;
  final String yearId;
  final dynamic classId;
  final String? className;
  final bool classWorkspace;
  final dynamic groupId;
  final String? groupName;
  final bool groupWorkspace;
  final String groupWorkspaceName;
  final dynamic subjectId;
  final String subjectName;
  final dynamic teacherId;
  final String teacherGuid;
  final String teacherName;
  final dynamic teacherAnnoId;
  final dynamic annoId;
  final String? languageId;
  final dynamic subjectCategoryId;
  final String subjectCategoryName;
  final dynamic typeId;
  final String typeName;
  final dynamic gradeTypeId;
  final String gradeTypeName;
  final dynamic taskPlaceId;
  final String taskPlaceName;
  final dynamic teacherAvatarTypeId;
  final String teacherAvatarTypePath;
  final dynamic taskGroupId;

  AllLessons({
    required this.schoolId,
    required this.yearId,
    this.classId,
    this.className,
    required this.classWorkspace,
    this.groupId,
    this.groupName,
    required this.groupWorkspace,
    required this.groupWorkspaceName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherGuid,
    required this.teacherName,
    this.teacherAnnoId,
    this.annoId,
    this.languageId,
    required this.subjectCategoryId,
    required this.subjectCategoryName,
    required this.typeId,
    required this.typeName,
    required this.gradeTypeId,
    required this.gradeTypeName,
    required this.taskPlaceId,
    required this.taskPlaceName,
    required this.teacherAvatarTypeId,
    required this.teacherAvatarTypePath,
    this.taskGroupId,
  });

  factory AllLessons.fromJson(Map<String, dynamic> json) => AllLessons(
        schoolId: json['intezmenyId']?.toString() ?? '',
        yearId: json['tanevId']?.toString() ?? '',
        classId: json['osztalyId'],
        className: json['osztalyNev']?.toString(),
        classWorkspace: json['osztalyMunkaTer'] == true,
        groupId: json['csoportId'],
        groupName: json['csoportNev']?.toString(),
        groupWorkspace: json['csoportMunkaTer'] == true,
        groupWorkspaceName: json['osztalyCsoportNev']?.toString() ?? '',
        subjectId: json['tantargyId'],
        subjectName: json['tantargyNev']?.toString() ?? '',
        teacherId: json['alkalmazottId'],
        teacherGuid: json['alkalmazottGuid']?.toString() ?? '',
        teacherName: json['alkalmazottNev']?.toString() ?? '',
        teacherAnnoId: json['alkalmazottUzenoFalId'],
        annoId: json['uzenoFalId'],
        languageId: json['nyelvId']?.toString(),
        subjectCategoryId: json['tantargyKategoriaId'],
        subjectCategoryName: json['tantargyKategoriaNev']?.toString() ?? '',
        typeId: json['tipusId'],
        typeName: json['tipusNev']?.toString() ?? '',
        gradeTypeId: json['evfolyamTipusId'],
        gradeTypeName: json['evfolyamTipusNev']?.toString() ?? '',
        taskPlaceId: json['feladatEllatasiHelyId'],
        taskPlaceName: json['feladatEllatasiHelyNev']?.toString() ?? '',
        teacherAvatarTypeId: json['alkalmazottAvatarTipusId'],
        teacherAvatarTypePath:
            json['alkalmazottAvatarEleres']?.toString() ?? '',
        taskGroupId: json['oraiFeladatGroupId'],
      );

  Map<String, dynamic> toJson() => {
        'intezmenyId': schoolId,
        'tanevId': yearId,
        'osztalyId': classId,
        'osztalyNev': className,
        'osztalyMunkaTer': classWorkspace,
        'csoportId': groupId,
        'csoportNev': groupName,
        'csoportMunkaTer': groupWorkspace,
        'osztalyCsoportNev': groupWorkspaceName,
        'tantargyId': subjectId,
        'tantargyNev': subjectName,
        'alkalmazottId': teacherId,
        'alkalmazottGuid': teacherGuid,
        'alkalmazottNev': teacherName,
        'alkalmazottUzenoFalId': teacherAnnoId,
        'uzenoFalId': annoId,
        'nyelvId': languageId,
        'tantargyKategoriaId': subjectCategoryId,
        'tantargyKategoriaNev': subjectCategoryName,
        'tipusId': typeId,
        'tipusNev': typeName,
        'evfolyamTipusId': gradeTypeId,
        'evfolyamTipusNev': gradeTypeName,
        'feladatEllatasiHelyId': taskPlaceId,
        'feladatEllatasiHelyNev': taskPlaceName,
        'alkalmazottAvatarTipusId': teacherAvatarTypeId,
        'alkalmazottAvatarEleres': teacherAvatarTypePath,
        'oraiFeladatGroupId': taskGroupId,
      };
}

List<AllLessons> lessonsFromJson(String str) =>
    List<AllLessons>.from(json.decode(str).map((x) => AllLessons.fromJson(x)));

String lessonsToJson(List<AllLessons> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
