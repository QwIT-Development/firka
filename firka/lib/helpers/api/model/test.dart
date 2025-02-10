import 'package:firka/helpers/api/model/subject.dart';

import 'generic.dart';

class Test {
  final String uid;
  final DateTime date;
  final DateTime reportDate;
  final String teacherName;
  final int lessonNumber;
  final Subject subject;
  final String subjectName;
  final String theme;
  final NameUidDesc method;
  final UidObj classGroup;

  Test({
    required this.uid,
    required this.date,
    required this.reportDate,
    required this.teacherName,
    required this.lessonNumber,
    required this.subject,
    required this.subjectName,
    required this.theme,
    required this.method,
    required this.classGroup,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      uid: json['Uid'],
      date: DateTime.parse(json['Datum']),
      reportDate: DateTime.parse(json['BejelentesDatuma']),
      teacherName: json['RogzitoTanarNeve'],
      lessonNumber: json['OrarendiOraOraszama'],
      subject: Subject.fromJson(json['Tantargy']),
      subjectName: json['TantargyNeve'],
      theme: json['Temaja'],
      method: NameUidDesc.fromJson(json['Modja']),
      classGroup: UidObj.fromJson(json['OsztalyCsoport']),
    );
  }

  @override
  String toString() {
    return 'Test('
        'uid: "$uid", '
        'date: $date, '
        'reportDate: $reportDate, '
        'teacherName: "$teacherName", '
        'lessonNumber: $lessonNumber, '
        'subject: $subject, '
        'subjectName: "$subjectName", '
        'theme: "$theme", '
        'method: $method, '
        'classGroup: $classGroup'
        ')';
  }
}
