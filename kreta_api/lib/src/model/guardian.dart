import 'generic.dart';

class Guardian extends NameUid {
  final String? email;
  final bool isLegalRepresentative;
  final String? phoneNumber;

  Guardian({
    required this.email,
    required this.isLegalRepresentative,
    required super.name,
    required this.phoneNumber,
    required super.uid,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      email: json['EmailCim'],
      isLegalRepresentative: json['IsTorvenyesKepviselo'],
      name: json['Nev'],
      phoneNumber: json['Telefonszam'],
      uid: json['Uid'],
    );
  }

  @override
  String toString() {
    return 'Guardian('
        'email: "$email", '
        'isLegalRepresentative: $isLegalRepresentative, '
        'name: "$name", '
        'phoneNumber: "$phoneNumber", '
        'uid: "$uid"'
        ')';
  }
}
