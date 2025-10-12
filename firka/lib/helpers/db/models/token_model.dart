import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firka/helpers/api/resp/token_grant.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:isar/isar.dart';

import '../../debug_helper.dart';

part 'token_model.g.dart';

@collection
class TokenModel {
  Id? studentIdNorm; // Custom unique student identifier with "G0" removed
  String? studentId; // Custom unique student identifier
  String? iss; // Institution id for student
  String? idToken; // Unique identifier for the token if needed
  String? accessToken; // The main auth token
  String? refreshToken; // Token used to refresh the access token
  DateTime? expiryDate;

  TokenModel();

  factory TokenModel.fromValues(Id studentIdNorm, studentId, String iss,
      String idToken, String accessToken, String refreshToken, int expiryDate) {
    var m = TokenModel();

    m.studentIdNorm = studentIdNorm;
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

    final payload = jwt as Map<String, dynamic>;
    final username = payload["kreta:user_name"].toString();
    if (username.isNumeric() ||
        (username.contains("G0") &&
            username.substring(0, username.length - 3).isNumeric())) {
      m.studentIdNorm = int.parse(username.toString().replaceAll("G0", ""));
    } else {
      // you would expect all usernames to be numeric
      // and for them be the student's student id, but NO
      final hash = sha256.convert(utf8.encode(username));
      final value = ((hash.bytes[0] << 24) |
              (hash.bytes[1] << 16) |
              (hash.bytes[2] << 8) |
              (hash.bytes[3])) >>>
          0;

      m.studentIdNorm = value & 0x3FFFFFFF;
    }
    m.studentId = payload["kreta:user_name"];
    m.iss = payload["kreta:institute_code"];
    m.idToken = resp.idToken;
    m.accessToken = resp.accessToken;
    m.refreshToken = resp.refreshToken;
    m.expiryDate = timeNow()
        .add(Duration(seconds: resp.expiresIn))
        .subtract(Duration(minutes: 1)); // just to be safe

    return m;
  }
}
