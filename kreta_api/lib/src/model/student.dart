import 'package:intl/intl.dart';

import 'generic.dart';
import 'guardian.dart';
import 'institution.dart';

class Student extends NameUid {
  final List<String> addressDataList;
  final BankAccount bankAccount;

  final DateTime birthdate;

  final String? emailAddress;
  final String? phoneNumber;

  final String schoolYearUID;

  final List<Guardian> guardianList;
  final String instituteCode;
  final String instituteName;

  final Institution institution;

  const Student({
    required this.addressDataList,
    required this.bankAccount,
    required this.birthdate,
    required this.emailAddress,
    required super.name,
    required this.phoneNumber,
    required this.schoolYearUID,
    required super.uid,
    required this.guardianList,
    required this.instituteCode,
    required this.instituteName,
    required this.institution,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    var guardianList = List<Guardian>.empty(growable: true);

    for (var item in json['Gondviselok']) {
      guardianList.add(Guardian.fromJson(item));
    }

    return Student(
      addressDataList: List<String>.from(json['Cimek'] as List),
      bankAccount: BankAccount.fromJson(json['Bankszamla']),
      birthdate: DateFormat('yyyy-M-d').parse(
        "${json['SzuletesiEv']}-${json['SzuletesiHonap']}-${json['SzuletesiNap']}",
      ),
      emailAddress: json['EmailCim'],
      name: json['Nev'],
      phoneNumber: json['Telefonszam'],
      schoolYearUID: json['TanevUid'],
      uid: json['Uid'],
      guardianList: guardianList,
      instituteCode: json['IntezmenyAzonosito'],
      instituteName: json['IntezmenyNev'],
      institution: Institution.fromJson(json['Intezmeny']),
    );
  }

  @override
  String toString() {
    return 'Student('
        'addressDataList: [$addressDataList], '
        'bankAccount: $bankAccount, '
        'birthDate: $birthdate, '
        'emailAddress: "$emailAddress", '
        'name: "$name", '
        'phoneNumber: "$phoneNumber", '
        'schoolYearUID: "$schoolYearUID", '
        'uid: "$uid", '
        'guardianList: [$guardianList], '
        'instituteCode: "$instituteCode", '
        'instituteName: "$instituteName", '
        ')';
  }
}

class BankAccount {
  final String? accountNumber;
  final bool? isReadOnly;
  final String? ownerName;
  final int? ownerType;

  const BankAccount({
    required this.accountNumber,
    required this.isReadOnly,
    required this.ownerName,
    required this.ownerType,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      accountNumber: json['BankszamlaSzam'],
      isReadOnly: json['IsReadOnly'],
      ownerName: json['BankszamlaTulajdonosNeve'],
      ownerType: json['BankszamlaTulajdonosTipusId'],
    );
  }

  @override
  String toString() {
    return 'BankAccount('
        'accountNumber: "$accountNumber", '
        'isReadOnly: "$isReadOnly", '
        'ownerName: "$ownerName", '
        'ownerType: "$ownerType"'
        ')';
  }
}
