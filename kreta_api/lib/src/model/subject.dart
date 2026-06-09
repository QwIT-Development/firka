import 'generic.dart';

class Subject extends NameUid {
  final NameUidDesc category;
  final int sortIndex;
  final String? teacherName;

  const Subject({
    required super.uid,
    required super.name,
    required this.category,
    required this.sortIndex,
    this.teacherName,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      uid: json['Uid'],
      name: json['Nev'],
      category: json.nameUidDesc('Kategoria')!,
      sortIndex: json['SortIndex'],
      teacherName: json['alkalmazottNev'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Uid': uid,
      'Nev': name,
      'Kategoria': category.toJson(),
      'SortIndex': sortIndex,
      'alkalmazottNev': teacherName,
    };
  }

  @override
  String toString() {
    return 'Subject('
        'uid: "$uid", '
        'name: "$name", '
        'category: $category, '
        'sortIndex: $sortIndex, '
        'nameOfTeacher: $teacherName'
        ')';
  }
}
