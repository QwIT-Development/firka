import '../extensions.dart';
import 'generic.dart';
import 'subject.dart';

class ClassGroup extends NameUid {
  final UidObj? headTeacher;
  final UidObj? substituteHeadTeacher;
  final NameUidDesc studyGroup;
  final int? studyGroupSortIndex;
  final NameUidDesc? studyTask;
  final bool isActive;
  final String type;

  ClassGroup({
    required super.uid,
    required super.name,
    required this.headTeacher,
    required this.substituteHeadTeacher,
    required this.studyGroup,
    required this.studyGroupSortIndex,
    required this.studyTask,
    required this.isActive,
    required this.type,
  });

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      uid: json['Uid'],
      name: json['Nev'],
      headTeacher: json.uid('OsztalyFonok'),
      substituteHeadTeacher: json.uid('OsztalyFonokHelyettes'),
      studyGroup: json.nameUidDesc('OktatasNevelesiKategoria')!,
      studyGroupSortIndex: json['OktatasNevelesiKategoriaSortIndex'],
      studyTask: json.nameUidDesc('OktatasNevelesiFeladat'),
      isActive: json['IsAktiv'],
      type: json['Tipus'],
    );
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

class SubjectAverage extends UidObj {
  final Subject subject;
  final double? average;
  final double? weightedSum;
  final double? weightedCount;

  SubjectAverage({
    required super.uid,
    required this.subject,
    this.average,
    this.weightedSum,
    this.weightedCount,
  });

  factory SubjectAverage.fromJson(Map<String, dynamic> json) {
    return SubjectAverage(
      uid: json['Uid'],
      subject: Subject.fromJson(json['Tantargy']),
      average: json.dbl('Atlag'),
      weightedSum: json.dbl('SulyozottOsztalyzatOsszege'),
      weightedCount: json.dbl('SulyozottOsztalyzatSzama'),
    );
  }

  @override
  String toString() {
    return 'SubjectAverage(uid: "$uid", name: "${subject.name}", category: "${subject.category.name}", average: $average)';
  }
}

class ClassGroupSubjectAverage extends UidObj {
  final Subject subject;
  final double? studentAverage;
  final double? classGroupAverage;

  ClassGroupSubjectAverage({
    required super.uid,
    required this.subject,
    this.classGroupAverage,
    this.studentAverage,
  });

  factory ClassGroupSubjectAverage.fromJson(Map<String, dynamic> json) {
    return ClassGroupSubjectAverage(
      uid: json['Uid'],
      subject: Subject.fromJson(json['Tantargy']),
      studentAverage: json.dbl('TanuloAtlag'),
      classGroupAverage: json.dbl('OsztalyCsoportAtlag'),
    );
  }

  @override
  String toString() {
    return 'ClassGroupSubjectAverage(uid: "$uid", subject: $subject)';
  }
}
