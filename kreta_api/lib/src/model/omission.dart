import '../extensions.dart';
import 'generic.dart';
import 'subject.dart';

class Omission extends UidObj {
  final Subject subject;
  final Class? c;
  final DateTime date;
  final String teacher;
  final NameUidDesc? type;
  final NameUidDesc? mode;
  final int? lateForMin;
  final DateTime createdAt;
  final String state;
  final NameUidDesc? proofType;
  final UidObj? classGroup;

  Omission({
    required super.uid,
    required this.subject,
    required this.c,
    required this.date,
    required this.teacher,
    this.type,
    this.mode,
    this.lateForMin,
    required this.createdAt,
    required this.state,
    required this.proofType,
    this.classGroup,
  });

  factory Omission.fromJson(Map<String, dynamic> json) {
    return Omission(
      uid: json['Uid'],
      subject: Subject.fromJson(json['Tantargy']),
      c: json['Osztaly'] != null ? Class.fromJson(json['Osztaly']) : null,
      date: json.localDate('Datum')!,
      teacher: json['RogzitoTanarNeve'],
      type: json.nameUidDesc('Tipus'),
      mode: json.nameUidDesc('Mod'),
      lateForMin: json['KesesPercben'],
      createdAt: json.localDate('KeszitesDatuma')!,
      state: json['IgazolasAllapota'],
      proofType: json.nameUidDesc('IgazolasTipusa')!,
      classGroup: json.uid('OsztalyCsoport'),
    );
  }

  @override
  String toString() {
    return 'Omission('
        'uid: "$uid", '
        'subject: $subject, '
        'c: $c, '
        'date: $date, '
        'teacher: "$teacher", '
        'type: $type, '
        'mode: $mode, '
        'lateForMin: $lateForMin, '
        'createdAt: $createdAt, '
        'state: "$state", '
        'proofType: $proofType, '
        'classGroup: $classGroup'
        ')';
  }
}

class Class {
  final DateTime start;
  final DateTime end;
  final int classNo;

  Class({required this.start, required this.end, required this.classNo});

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      start: json.localDate('KezdoDatum')!,
      end: json.localDate('VegDatum')!,
      classNo: json['Oraszam'],
    );
  }

  @override
  String toString() {
    return 'Class('
        'start: "$start", '
        'end: "$end", '
        'classNo: $classNo'
        ')';
  }
}
