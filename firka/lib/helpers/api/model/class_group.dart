import 'package:firka/helpers/api/model/generic.dart';

class ClassGroup {
  final String uid;
  final String name;
  final UidObj? headTeacher;
  final UidObj? substituteHeadTeacher;
  final NameUidDesc studyGroup;
  final int? studyGroupSortIndex;
  final bool isActive;
  final String type;

  ClassGroup(
      {required this.uid,
      required this.name,
      required this.headTeacher,
      required this.substituteHeadTeacher,
      required this.studyGroup,
      required this.studyGroupSortIndex,
      required this.isActive,
      required this.type});

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
        uid: json['Uid'],
        name: json['Nev'],
        headTeacher: json['OsztalyFonok'] != null
            ? UidObj.fromJson(json['OsztalyFonok'])
            : null,
        substituteHeadTeacher: json['OsztalyFonokHelyettes'] != null
            ? UidObj.fromJson(json['OsztalyFonokHelyettes'])
            : null,
        studyGroup: NameUidDesc.fromJson(json['OktatasNevelesiKategoria']),
        studyGroupSortIndex: json['OktatasNevelesiKategoriaSortIndex'],
        isActive: json['IsAktiv'],
        type: json['Tipus']);
  }

  @override
  String toString() {
    return 'ClassGroup('
        'uid: "$uid", '
        'name: "$name", '
        'headTeacher: $headTeacher, '
        'substituteHeadTeacher: $substituteHeadTeacher, '
        'studyGroup: $studyGroup, '
        'studyGroupSortIndex: $studyGroupSortIndex, '
        'isActive: $isActive, '
        'type: "$type"'
        ')';
  }
}
