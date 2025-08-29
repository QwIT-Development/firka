import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/subject.dart';

class Lesson {
  final String uid;
  final String date;
  final DateTime start;
  final DateTime end;
  final String name;
  final int? lessonNumber;
  final int? lessonSeqNumber;
  final NameUid? classGroup;
  final String? teacher;
  final Subject? subject;
  final String? theme;
  final String? roomName;
  final NameUidDesc type;
  final NameUidDesc? studentPresence;
  final NameUidDesc state;
  final String? substituteTeacher;
  final String? homeworkUid;
  final String? taskGroupUid;
  final String? languageTaskGroupUid;
  final String? assessmentUid;
  final bool canStudentEditHomework;
  final bool isHomeworkComplete;
  final List<NameUid> attachments;
  final bool isDigitalLesson;
  final String? digitalDeviceList;
  final String? digitalPlatformType;
  final List<String> digitalSupportDeviceTypeList;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  Lesson({
    required this.uid,
    required this.date,
    required this.start,
    required this.end,
    required this.name,
    this.lessonNumber,
    this.lessonSeqNumber,
    this.classGroup,
    this.teacher,
    this.subject,
    this.theme,
    this.roomName,
    required this.type,
    this.studentPresence,
    required this.state,
    this.substituteTeacher,
    this.homeworkUid,
    this.taskGroupUid,
    this.languageTaskGroupUid,
    this.assessmentUid,
    required this.canStudentEditHomework,
    required this.isHomeworkComplete,
    required this.attachments,
    required this.isDigitalLesson,
    this.digitalDeviceList,
    this.digitalPlatformType,
    required this.digitalSupportDeviceTypeList,
    required this.createdAt,
    required this.lastModifiedAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    var attachments = List<NameUid>.empty(growable: true);
    var rawAttachments = json['Csatolmanyok'];

    for (var attachment in rawAttachments) {
      attachments.add(NameUid.fromJson(attachment));
    }
    return Lesson(
      uid: json['Uid'],
      date: json['Datum'],
      start: DateTime.parse(json['KezdetIdopont']).toLocal(),
      end: DateTime.parse(json['VegIdopont']).toLocal(),
      name: json['Nev'],
      lessonNumber: json['Oraszam'],
      lessonSeqNumber: json['OraEvesSorszama'],
      classGroup: json['OsztalyCsoport'] != null
          ? NameUid.fromJson(json['OsztalyCsoport'])
          : null,
      teacher: json['TanarNeve'],
      subject:
          json['Tantargy'] != null ? Subject.fromJson(json['Tantargy']) : null,
      theme: json['Tema'],
      roomName: json['TeremNeve'],
      type: NameUidDesc.fromJson(json['Tipus']),
      studentPresence: json['TanuloJelenlet'] != null
          ? NameUidDesc.fromJson(json['TanuloJelenlet'])
          : null,
      state: NameUidDesc.fromJson(json['Allapot']),
      substituteTeacher: json['HelyettesTanarNeve'],
      homeworkUid: json['HaziFeladatUid'],
      taskGroupUid: json['FeladatGroupUid'],
      languageTaskGroupUid: json['NyelviFeladatGroupUid'],
      assessmentUid: json['BejelentettSzamonkeresUid'],
      canStudentEditHomework: json['IsTanuloHaziFeladatEnabled'],
      isHomeworkComplete: json['IsHaziFeladatMegoldva'],
      attachments: attachments,
      isDigitalLesson: json['IsDigitalisOra'],
      digitalDeviceList: json['DigitalisEszkozTipus'],
      digitalPlatformType: json['DigitalisPlatformTipus'],
      digitalSupportDeviceTypeList:
          json['DigitalisTamogatoEszkozTipusList'] != null
              ? List<String>.from(json['DigitalisTamogatoEszkozTipusList'])
              : List<String>.empty(),
      createdAt: DateTime.parse(json['Letrehozas']).toLocal(),
      lastModifiedAt: DateTime.parse(json['UtolsoModositas']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    List<dynamic> rawAttachments = [];

    for (var item in attachments) {
      rawAttachments.add(item.toJson());
    }

    return {
      'Uid': uid,
      'Datum': date,
      'KezdetIdopont': start.toIso8601String(),
      'VegIdopont': end.toIso8601String(),
      'Nev': name,
      'Oraszam': lessonNumber,
      'OraEvesSorszama': lessonSeqNumber,
      'OsztalyCsoport': classGroup,
      'TanarNeve': teacher,
      'Tantargy': subject?.toJson(),
      'Tema': theme,
      'TeremNeve': roomName,
      'Tipus': type.toJson(),
      'TanuloJelenlet': studentPresence?.toJson(),
      'Allapot': state.toJson(),
      'HelyettesTanarNeve': substituteTeacher,
      'HaziFeladatUid': homeworkUid,
      'FeladatGroupUid': taskGroupUid,
      'NyelviFeladatGroupUid': languageTaskGroupUid,
      'BejelentettSzamonkeresUid': assessmentUid,
      'IsTanuloHaziFeladatEnabled': canStudentEditHomework,
      'IsHaziFeladatMegoldva': isHomeworkComplete,
      'Csatolmanyok': rawAttachments,
      'IsDigitalisOra': isDigitalLesson,
      'DigitalisEszkozTipus': digitalDeviceList,
      'DigitalisPlatformTipus': digitalPlatformType,
      'DigitalisTamogatoEszkozTipusList': digitalSupportDeviceTypeList,
      'Letrehozas': createdAt.toIso8601String(),
      'UtolsoModositas': lastModifiedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Lesson('
        'uid: "$uid", '
        'date: "$date", '
        'start: $start, '
        'end: $end, '
        'name: "$name", '
        'lessonNumber: $lessonNumber, '
        'lessonSeqNumber: $lessonSeqNumber, '
        'classGroup: $classGroup, '
        'teacher: "$teacher", '
        'subject: $subject, '
        'theme: "$theme", '
        'roomName: "$roomName", '
        'type: $type, '
        'studentPresence: $studentPresence, '
        'state: $state, '
        'substituteTeacher: "$substituteTeacher", '
        'homeworkUid: "$homeworkUid", '
        'taskGroupUid: "$taskGroupUid", '
        'languageTaskGroupUid: "$languageTaskGroupUid", '
        'assessmentUid: "$assessmentUid", '
        'canStudentEditHomework: $canStudentEditHomework, '
        'isHomeworkComplete: $isHomeworkComplete, '
        'attachments: $attachments, '
        'isDigitalLesson: $isDigitalLesson, '
        'digitalDeviceList: "$digitalDeviceList", '
        'digitalPlatformType: "$digitalPlatformType", '
        'digitalSupportDeviceTypeList: $digitalSupportDeviceTypeList, '
        'create: $createdAt, '
        'lastModified: $lastModifiedAt'
        ')';
  }
}
