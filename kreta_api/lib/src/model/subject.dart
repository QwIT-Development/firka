import 'generic.dart';

class Subject extends NameUid {
  final NameUidDesc category;
  final int sortIndex;

  Subject({
    required super.uid,
    required super.name,
    required this.category,
    required this.sortIndex,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      uid: json['Uid'],
      name: json['Nev'],
      category: json.nameUidDesc('Kategoria')!,
      sortIndex: json['SortIndex'],
    );
  }

  @override
  String toString() {
    return 'Subject('
        'uid: "$uid", '
        'name: "$name", '
        'category: $category, '
        'sortIndex: $sortIndex, '
        ')';
  }
}
