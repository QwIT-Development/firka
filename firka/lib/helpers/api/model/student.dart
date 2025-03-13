/*
  Firka, alternative e-Kréta client.
  Copyright (C) 2025  QwIT Development

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'package:firka/helpers/api/model/bank_account.dart';
import 'package:firka/helpers/api/model/guardian.dart';
import 'package:firka/helpers/api/model/institution.dart';

class Student {

  final List<String> addressDataList;
  final BankAccount bankAccount;
  
  final int yearOfBirth;
  final int monthOfBirth;
  final int dayOfBirth;

  final String emailAddress;
  final String name;
  final String phoneNumber;

  final int schoolYearUID;
  final String uid;

  final List<Guardian> guardianList;
  final String instituteCode;
  final String instituteName;

  final Institution institution;


  Student({
    required this.addressDataList,
    required this.bankAccount,
    required this.yearOfBirth,
    required this.monthOfBirth,
    required this.dayOfBirth,
    required this.emailAddress,
    required this.name,
    required this.phoneNumber,
    required this.schoolYearUID,
    required this.uid,
    required this.guardianList,
    required this.instituteCode,
    required this.instituteName,
    required this.institution
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      addressDataList: json['Cimek'],
      bankAccount: json['Bankszamla'],
      yearOfBirth: json['SzuletesiEv'],
      monthOfBirth: json['SzuletesiHonap'],
      dayOfBirth: json['SzuletesiNap'],
      emailAddress: json['EmailCim'],
      name: json['Nev'],
      phoneNumber: json['Telefonszam'],
      schoolYearUID: json['TanevUid'],
      uid: json['Uid'],
      guardianList: json['Gondviselok'],
      instituteCode: json['IntezmenyAzonosito'],
      instituteName: json['IntezmenyNev'],
      institution: json['Intezmeny']
    );
  }

}