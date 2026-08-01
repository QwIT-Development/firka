import 'generic.dart';

class DktSubject extends Identifiable {
  final int id;
  final String name;
  final String teacherName;
  final int? classGroupId; // null = whole class
  final String groupName; // if group null then class name
  final String? languageCode; // ISO 639-1:2002; null = non-language subject
  final int typeId; // 0 = not removed

  DktSubject({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.typeId,
    this.languageCode,
    this.classGroupId,
    required this.groupName,
  });

  factory DktSubject.fromJson(Map<String, dynamic> json) {
    return DktSubject(
      id: json["tantargyId"],
      name: json["tantargyNev"],
      teacherName: json["alkalmazottNev"],
      classGroupId: json["csoportId"],
      groupName: json["osztalyCsoportNev"],
      typeId: json["tipusId"],
      languageCode: json["nyelvId"],
    );
  }
}
