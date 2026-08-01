import 'generic.dart';
import 'subject.dart';

class Grade extends UidObj {
  final DateTime recordDate;
  final DateTime creationDate;
  final DateTime? ackDate;
  final Subject subject;
  final String? topic;
  final NameUidDesc type;
  final NameUidDesc? mode;
  final NameUidDesc valueType;
  final String teacher;
  final String? kind;
  final int? numericValue;
  final String strValue;
  final int? weightPercentage;
  final String? shortStrValue;
  final UidObj classGroup;
  final int sortIndex;

  Grade({
    required super.uid,
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
    required this.classGroup,
    required this.sortIndex,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      uid: json['Uid'],
      recordDate: DateTime.parse(json['RogzitesDatuma']).toLocal(),
      creationDate: DateTime.parse(json['KeszitesDatuma']).toLocal(),
      ackDate: json['LattamozasDatuma'] != null
          ? DateTime.parse(json['LattamozasDatuma']).toLocal()
          : null,
      subject: Subject.fromJson(json['Tantargy']),
      topic: json['Tema'],
      type: json.nameUidDesc('Tipus')!,
      mode: json.nameUidDesc('Mod'),
      valueType: json.nameUidDesc('ErtekFajta')!,
      teacher: json['ErtekeloTanarNeve'],
      kind: json['Kind'],
      numericValue: json['SzamErtek'],
      strValue: json['SzovegesErtek'],
      weightPercentage: json['SulySzazalekErteke'],
      shortStrValue: json['SzovegesErtekelesRovidNev'],
      classGroup: json.uid('OsztalyCsoport')!,
      sortIndex: json['SortIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Uid': uid,
      'RogzitesDatuma': recordDate.toUtc().toIso8601String(),
      'KeszitesDatuma': creationDate.toUtc().toIso8601String(),
      'LattamozasDatuma': ackDate?.toUtc().toIso8601String(),
      'Tantargy': subject.toJson(),
      'Tema': topic,
      'Tipus': type.toJson(),
      'Mod': mode?.toJson(),
      'ErtekFajta': valueType.toJson(),
      'ErtekeloTanarNeve': teacher,
      'Kind': kind,
      'SzamErtek': numericValue,
      'SzovegesErtek': strValue,
      'SulySzazalekErteke': weightPercentage,
      'SzovegesErtekelesRovidNev': shortStrValue,
      'OsztalyCsoport': classGroup,
      'SortIndex': sortIndex,
    };
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
        'classGroup: ${classGroup}, '
        'sortIndex: $sortIndex'
        ')';
  }
}
