import 'generic.dart';

class Subject {
  final String uid;
  final String name;
  final NameUidDesc category;
  final int sortIndex;

  Subject(
      {required this.uid,
      required this.name,
      required this.category,
      required this.sortIndex});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
        uid: json['Uid'],
        name: json['Nev'],
        category: NameUidDesc.fromJson(json['Kategoria']),
        sortIndex: json['SortIndex']);
  }

  @override
  String toString() {
    return 'Subject('
        'uid: "$uid", '
        'name: "$name", '
        'category: $category, '
        'sortIndex: $sortIndex'
        ')';
  }
}
