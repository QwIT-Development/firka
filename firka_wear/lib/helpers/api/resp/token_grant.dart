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

class TokenGrantResponse {
  final String idToken;
  final String accessToken;
  final int expiresIn;
  final String tokenType;
  final String refreshToken;
  final String scope;

  TokenGrantResponse(
      {required this.idToken,
      required this.accessToken,
      required this.expiresIn,
      required this.tokenType,
      required this.refreshToken,
      required this.scope});

  factory TokenGrantResponse.fromJson(Map<String, dynamic> json) {
    return TokenGrantResponse(
        idToken: json['id_token'],
        accessToken: json['access_token'],
        expiresIn: json['expires_in'],
        tokenType: json['token_type'],
        refreshToken: json['refresh_token'],
        scope: json['scope']);
  }

  @override
  String toString() {
    return 'TokenGrant(idToken: "$idToken", accessToken: "$accessToken", '
        'expiresIn: $expiresIn, '
        'tokenType: "$tokenType", '
        'refreshToken: "$refreshToken", '
        'scope: "$scope"'
        ')';
  }
}
