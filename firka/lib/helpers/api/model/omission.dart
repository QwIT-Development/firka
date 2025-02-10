import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/subject.dart';

class Omission {
  final String uid;
  final Subject subject;
  final Class? c;
  final DateTime date;
  final String teacher;
  final NameUidDesc? type;
  final NameUidDesc? mode;
  final int? lateForMin;
  final DateTime createdAt;
  final String state;
  final NameUidDesc proofType;
  final UidObj? classGroup;

  Omission({
    required this.uid,
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
      date: DateTime.parse(json['Datum']),
      teacher: json['RogzitoTanarNeve'],
      type: json['Tipus'] != null ? NameUidDesc.fromJson(json['Tipus']) : null,
      mode: json['Mod'] != null ? NameUidDesc.fromJson(json['Mod']) : null,
      lateForMin: json['KesesPercben'],
      createdAt: DateTime.parse(json['KeszitesDatuma']),
      state: json['IgazolasAllapota'],
      proofType: NameUidDesc.fromJson(json['IgazolasTipusa']),
      classGroup: json['OsztalyCsoport'] != null
          ? UidObj.fromJson(json['OsztalyCsoport'])
          : null,
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

  Class({
    required this.start,
    required this.end,
    required this.classNo,
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      start: DateTime.parse(json['KezdoDatum']),
      end: DateTime.parse(json['VegDatum']),
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
