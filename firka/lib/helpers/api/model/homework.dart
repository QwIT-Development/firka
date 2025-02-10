import 'package:firka/helpers/api/model/subject.dart';

import 'generic.dart';

class Homework {
  final String uid;
  final Subject subject;
  final String subjectName;
  final String teacherName;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime creationDate;
  final bool isCreatedByTeacher;
  final bool isDone;
  final bool canBeSubmitted;
  final UidObj classGroup;
  final bool canAttach;

  Homework(
      {required this.uid,
      required this.subject,
      required this.subjectName,
      required this.teacherName,
      required this.description,
      required this.startDate,
      required this.dueDate,
      required this.creationDate,
      required this.isCreatedByTeacher,
      required this.isDone,
      required this.canBeSubmitted,
      required this.classGroup,
      required this.canAttach});

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
        uid: json["Uid"],
        subject: Subject.fromJson(json["Tantargy"]),
        subjectName: json["TantargyNeve"],
        teacherName: json["RogzitoTanarNeve"],
        description: json["Szoveg"],
        startDate: DateTime.parse(json["FeladasDatuma"]).toLocal(),
        dueDate: DateTime.parse(json["HataridoDatuma"]).toLocal(),
        creationDate: DateTime.parse(json["RogzitesIdopontja"]).toLocal(),
        isCreatedByTeacher: json["IsTanarRogzitette"],
        isDone: json["IsMegoldva"],
        canBeSubmitted: json["IsBeadhato"],
        classGroup: UidObj.fromJson(json["OsztalyCsoport"]),
        canAttach: json["IsCsatolasEngedelyezes"]);
  }

  @override
  String toString() {
    return 'Homework('
        'uid: "$uid", '
        'subject: $subject, '
        'subjectName: "$subjectName", '
        'teacherName: "$teacherName", '
        'description: "$description", '
        'startDate: $startDate, '
        'dueDate: $dueDate, '
        'creationDate: $creationDate, '
        'isCreatedByTeacher: $isCreatedByTeacher, '
        'isDone: $isDone, '
        'canBeSubmitted: $canBeSubmitted, '
        'classGroup: $classGroup, '
        'canAttach: $canAttach'
        ')';
  }
}
