import 'package:firka/helpers/api/model/generic.dart';

class ClassGroup {
  final String uid;
  final String name;
  final UidObj? headTeacher;
  final UidObj? substituteHeadTeacher;
  final NameUidDesc studyGroup;
  final int? studyGroupSortIndex;
  final NameUidDesc? studyTask;
  final bool isActive;
  final String type;

  ClassGroup(
      {required this.uid,
      required this.name,
      required this.headTeacher,
      required this.substituteHeadTeacher,
      required this.studyGroup,
      required this.studyGroupSortIndex,
      required this.studyTask,
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
        studyTask: json['OktatasNevelesiFeladat'] != null
            ? NameUidDesc.fromJson(json['OktatasNevelesiFeladat'])
            : null,
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
        'studyTask: $studyTask, '
        'isActive: $isActive, '
        'type: "$type"'
        ')';
  }
}

class SubjectAverage {
  final String uid;
  final String name;
  final String? teacherName;
  final String subjectCategoryId;
  final String subjectCategoryName;
  final String subjectCategoryDescription;
  final double? average;
  final double? weightedSum;
  final double? weightedCount;
  final int sortIndex;

  SubjectAverage({
    required this.uid,
    required this.name,
    this.teacherName,
    required this.subjectCategoryId,
    required this.subjectCategoryName,
    required this.subjectCategoryDescription,
    this.average,
    this.weightedSum,
    this.weightedCount,
    required this.sortIndex,
  });

  factory SubjectAverage.fromJson(Map<String, dynamic> json) {
    final tantargy = json['Tantargy'] ?? {};
    final kategori = tantargy['Kategoria'] ?? {};

    return SubjectAverage(
      uid: json['Uid'] ?? '',
      name: tantargy['Nev'] ?? '',
      teacherName: json['TeacherName'],
      subjectCategoryId: kategori['Uid'] ?? '',
      subjectCategoryName: kategori['Nev'] ?? '',
      subjectCategoryDescription: kategori['Leiras'] ?? '',
      average: json['Atlag'] != null ? (json['Atlag'] as num).toDouble() : null,
      weightedSum: json['SulyozottOsztalyzatOsszege'] != null
          ? (json['SulyozottOsztalyzatOsszege'] as num).toDouble()
          : null,
      weightedCount: json['SulyozottOsztalyzatSzama'] != null
          ? (json['SulyozottOsztalyzatSzama'] as num).toDouble()
          : null,
      sortIndex: tantargy['SortIndex'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SubjectAverage(uid: "$uid", name: "$name", category: "$subjectCategoryName", average: $average)';
  }
}
