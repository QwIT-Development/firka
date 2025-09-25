import 'generic.dart';

class Subject {
  final String uid;
  final String name;
  final NameUidDesc category;
  final int sortIndex;
  final String? teacherName;

  Subject({
    required this.uid,
    required this.name,
    required this.category,
    required this.sortIndex,
    this.teacherName,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      uid: json['Uid'],
      name: json['Nev'],
      category: NameUidDesc.fromJson(json['Kategoria']),
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
