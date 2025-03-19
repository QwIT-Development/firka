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

import 'package:isar/isar.dart';
part 'token_model.g.dart';

class TokenModel {
  @Id()
  int studentId = 0; // Custom unique student identifier

  String? idToken; // Unique identifier for the token if needed
  String? accessToken; // The main auth token
  String? refreshToken; // Token used to refresh the access token
  DateTime? expiryDate;

}
