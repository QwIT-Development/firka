import 'package:firka/helpers/api/model/guardian.dart';
import 'package:firka/helpers/api/model/institution.dart';
import 'package:firka/helpers/json_helper.dart';
import 'package:intl/intl.dart';

class Student {
  final List<String> addressDataList;
  final BankAccount bankAccount;

  // final int yearOfBirth;
  // final int monthOfBirth;
  // final int dayOfBirth;
  final DateTime birthdate;

  final String? emailAddress;
  final String name;
  final String? phoneNumber;

  final String schoolYearUID;
  final String uid;

  final List<Guardian> guardianList;
  final String instituteCode;
  final String instituteName;

  final Institution institution;

  Student(
      {required this.addressDataList,
      required this.bankAccount,
      // required this.yearOfBirth,
      // required this.monthOfBirth,
      // required this.dayOfBirth,
      required this.birthdate,
      required this.emailAddress,
      required this.name,
      required this.phoneNumber,
      required this.schoolYearUID,
      required this.uid,
      required this.guardianList,
      required this.instituteCode,
      required this.instituteName,
      required this.institution});

  factory Student.fromJson(Map<String, dynamic> json) {
    var guardianList = List<Guardian>.empty(growable: true);

    for (var item in json['Gondviselok']) {
      guardianList.add(Guardian.fromJson(item));
    }

    return Student(
        addressDataList: listToTyped<String>(json['Cimek']),
        bankAccount: BankAccount.fromJson(json['Bankszamla']),
        birthdate: DateFormat('yyyy-M-d').parse(
            "${json['SzuletesiEv']}-${json['SzuletesiHonap']}-${json['SzuletesiNap']}"),
        emailAddress: json['EmailCim'],
        name: json['Nev'],
        phoneNumber: json['Telefonszam'],
        schoolYearUID: json['TanevUid'],
        uid: json['Uid'],
        guardianList: guardianList,
        instituteCode: json['IntezmenyAzonosito'],
        instituteName: json['IntezmenyNev'],
        institution: Institution.fromJson(json['Intezmeny']));
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

  BankAccount(
      {required this.accountNumber,
      required this.isReadOnly,
      required this.ownerName,
      required this.ownerType});

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
        accountNumber: json['BankszamlaSzam'],
        isReadOnly: json['IsReadOnly'],
        ownerName: json['BankszamlaTulajdonosNeve'],
        ownerType: json['BankszamlaTulajdonosTipusId']);
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
