class NameUidDesc {
  final String uid;
  final String? name;
  final String? description;

  NameUidDesc(
      {required this.uid, required this.name, required this.description});

  factory NameUidDesc.fromJson(Map<String, dynamic> json) {
    return NameUidDesc(
        uid: json['Uid'], name: json['Nev'], description: json['Leiras']);
  }

  @override
  String toString() {
    return 'NameUidDesc('
        'uid: "$uid", '
        'name: "$name", '
        'description: "$description"'
        ')';
  }
}

class NameUid {
  final String uid;
  final String name;

  NameUid({
    required this.uid,
    required this.name,
  });

  factory NameUid.fromJson(Map<String, dynamic> json) {
    return NameUid(
      uid: json['Uid'],
      name: json['Nev'],
    );
  }
}

class UidObj {
  final String uid;

  UidObj({required this.uid});

  factory UidObj.fromJson(Map<String, dynamic> json) {
    return UidObj(
      uid: json['Uid'],
    );
  }

  @override
  String toString() {
    return 'UidObj('
        'uid: "$uid"'
        ')';
  }
}
