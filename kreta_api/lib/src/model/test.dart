import '../extensions.dart';
import 'generic.dart';
import 'subject.dart';

class Test extends UidObj {
  final DateTime date;
  final DateTime reportDate;
  final String teacherName;
  final int lessonNumber;
  final Subject subject;
  final String subjectName;
  final String? theme;
  final NameUidDesc method;
  final UidObj classGroup;

  Test({
    required super.uid,
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
      date: json.localDate('Datum')!,
      reportDate: json.localDate('BejelentesDatuma')!,
      teacherName: json['RogzitoTanarNeve'],
      lessonNumber: json['OrarendiOraOraszama'],
      subject: Subject.fromJson(json['Tantargy']),
      subjectName: json['TantargyNeve'],
      theme: json['Temaja'],
      method: json.nameUidDesc('Modja')!,
      classGroup: json.uid('OsztalyCsoport')!,
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
