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
