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
