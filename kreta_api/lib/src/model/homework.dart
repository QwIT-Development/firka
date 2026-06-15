import '../extensions.dart';
import 'generic.dart';
import 'subject.dart';

class Homework extends UidObj {
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

  const Homework({
    required super.uid,
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
    required this.canAttach,
  });

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      uid: json["Uid"],
      subject: Subject.fromJson(json["Tantargy"]),
      subjectName: json["TantargyNeve"],
      teacherName: json["RogzitoTanarNeve"],
      description: json["Szoveg"],
      startDate: json.localDate("FeladasDatuma")!,
      dueDate: json.localDate("HataridoDatuma")!,
      creationDate: json.localDate("RogzitesIdopontja")!,
      isCreatedByTeacher: json["IsTanarRogzitette"],
      isDone: json["IsMegoldva"],
      canBeSubmitted: json["IsBeadhato"],
      classGroup: json.uid("OsztalyCsoport")!,
      canAttach: json["IsCsatolasEngedelyezes"],
    );
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
