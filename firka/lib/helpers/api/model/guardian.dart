class Guardian {
  final String? email;
  final bool isLegalRepresentative;
  final String? name;
  final String? phoneNumber;
  final String uid;

  Guardian(
      {required this.email,
      required this.isLegalRepresentative,
      required this.name,
      required this.phoneNumber,
      required this.uid});

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
        email: json['EmailCim'],
        isLegalRepresentative: json['IsTorvenyesKepviselo'],
        name: json['Nev'],
        phoneNumber: json['Telefonszam'],
        uid: json['Uid']);
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
