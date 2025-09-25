import 'generic.dart';

class Subject {
  final String uid;
  final String name;
  final NameUidDesc category;
  final int sortIndex;
  final String? alkalmazottNev;

  Subject({
    required this.uid,
    required this.name,
    required this.category,
    required this.sortIndex,
    this.alkalmazottNev,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      uid: json['Uid'],
      name: json['Nev'],
      category: NameUidDesc.fromJson(json['Kategoria']),
      sortIndex: json['SortIndex'],
      alkalmazottNev: json['alkalmazottNev'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Uid': uid,
      'Nev': name,
      'Kategoria': category.toJson(),
      'SortIndex': sortIndex,
      'alkalmazottNev': alkalmazottNev,
    };
  }

  @override
  String toString() {
    return 'Subject('
        'uid: "$uid", '
        'name: "$name", '
        'category: $category, '
        'sortIndex: $sortIndex, '
        'alkalmazottNev: $alkalmazottNev'
        ')';
  }
}
