import 'package:firka/helpers/api/model/generic.dart';
import 'package:firka/helpers/api/model/subject.dart';

class Grade {
  final String uid;
  final DateTime recordDate;
  final DateTime creationDate;
  final DateTime? ackDate;
  final Subject subject;
  final String? topic;
  final NameUidDesc type;
  final NameUidDesc? mode;
  NameUidDesc valueType;
  final String teacher;
  final String? kind;
  int? numericValue;
  final String strValue;
  final int? weightPercentage;
  final String? shortStrValue;
  final UidObj? classGroup;
  final int sortIndex;

  Grade(
      {required this.uid,
      required this.recordDate,
      required this.creationDate,
      this.ackDate,
      required this.subject,
      this.topic,
      required this.type,
      this.mode,
      required this.valueType,
      required this.teacher,
      this.kind,
      this.numericValue,
      required this.strValue,
      this.weightPercentage,
      this.shortStrValue,
      this.classGroup,
      required this.sortIndex});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      uid: json['Uid'],
      recordDate: DateTime.parse(json['RogzitesDatuma']),
      creationDate: DateTime.parse(json['KeszitesDatuma']),
      ackDate: json['LattamozasDatuma'] != null
          ? DateTime.parse(json['LattamozasDatuma'])
          : null,
      subject: Subject.fromJson(json['Tantargy']),
      topic: json['Tema'],
      type: NameUidDesc.fromJson(json['Tipus']),
      mode: json['Mod'] != null ? NameUidDesc.fromJson(json['Mod']) : null,
      valueType: NameUidDesc.fromJson(json['ErtekFajta']),
      teacher: json['ErtekeloTanarNeve'],
      kind: json['Kind'],
      numericValue: json['SzamErtek'],
      strValue: json['SzovegesErtek'],
      weightPercentage: json['SulySzazalekErteke'],
      shortStrValue: json['SzovegesErtekelesRovidNev'],
      classGroup: json['OsztalyCsoport'] != null
          ? UidObj.fromJson(json['OsztalyCsoport'])
          : null,
      sortIndex: json['SortIndex'],
    );
  }

  @override
  String toString() {
    return 'Grade('
        'uid: "$uid", '
        'recordDate: "$recordDate", '
        'creationDate: "$creationDate", '
        'ackDate: "${ackDate ?? 'null'}", '
        'subject: $subject, '
        'topic: "${topic ?? 'null'}", '
        'type: $type, '
        'mode: ${mode ?? 'null'}, '
        'valueType: $valueType, '
        'teacher: "$teacher", '
        'kind: "${kind ?? 'null'}", '
        'numericValue: ${numericValue ?? 'null'}, '
        'strValue: "$strValue", '
        'weightPercentage: ${weightPercentage ?? 'null'}, '
        'shortStrValue: "${shortStrValue ?? 'null'}", '
        'classGroup: ${classGroup ?? 'null'}, '
        'sortIndex: $sortIndex'
        ')';
  }
}
