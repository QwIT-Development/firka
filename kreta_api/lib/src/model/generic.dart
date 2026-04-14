class NameUidDesc extends NameUid {
  final String description;

  NameUidDesc({
    required super.uid,
    required super.name,
    required this.description,
  });

  factory NameUidDesc.fromJson(Map<String, dynamic> json) {
    return NameUidDesc(
      uid: json['Uid'],
      name: json['Nev'],
      description: json['Leiras'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'Uid': uid, 'Nev': name, 'Leiras': description};
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

class NameUid extends UidObj {
  final String name;

  NameUid({required super.uid, required this.name});

  factory NameUid.fromJson(Map<String, dynamic> json) {
    return NameUid(uid: json['Uid'], name: json['Nev']);
  }

  Map<String, dynamic> toJson() {
    return {'Uid': uid, 'Nev': name};
  }
}

class UidObj {
  final String uid;

  UidObj({required this.uid});

  factory UidObj.fromJson(Map<String, dynamic> json) {
    return UidObj(uid: json['Uid']);
  }

  @override
  String toString() {
    return 'UidObj('
        'uid: "$uid"'
        ')';
  }
}

extension ToUidObj on Map<String, dynamic> {
  UidObj? uid(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return UidObj.fromJson(value);
  }

  NameUid? nameUid(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return NameUid.fromJson(value);
  }

  NameUidDesc? nameUidDesc(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return NameUidDesc.fromJson(value);
  }
}
