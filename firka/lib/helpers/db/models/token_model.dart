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

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firka/helpers/api/resp/token_grant.dart';
import 'package:isar/isar.dart';

import '../../debug_helper.dart';

part 'token_model.g.dart';

@collection
class TokenModel {
  Id? studentId; // Custom unique student identifier
  String? iss; // Institution id for student
  String? idToken; // Unique identifier for the token if needed
  String? accessToken; // The main auth token
  String? refreshToken; // Token used to refresh the access token
  DateTime? expiryDate;

  TokenModel();

  factory TokenModel.fromValues(Id studentId, String iss, String idToken,
      String accessToken, String refreshToken, int expiryDate) {
    var m = TokenModel();

    m.studentId = studentId;
    m.iss = iss;
    m.idToken = idToken;
    m.accessToken = accessToken;
    m.refreshToken = refreshToken;
    m.expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryDate);

    return m;
  }

  factory TokenModel.fromResp(TokenGrantResponse resp) {
    var m = TokenModel();
    final jwt = JWT.decode(resp.idToken);

    // TODO: Add a proper model for jwt id

    m.studentId = int.parse(jwt.payload["kreta:user_name"]);
    m.iss = jwt.payload["kreta:institute_code"];
    m.idToken = resp.idToken;
    m.accessToken = resp.accessToken;
    m.refreshToken = resp.refreshToken;
    m.expiryDate = timeNow()
        .add(Duration(seconds: resp.expiresIn))
        .subtract(Duration(minutes: 10)); // just to be safe

    return m;
  }
}
