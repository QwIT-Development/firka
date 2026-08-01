import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:isar_community/isar.dart';

part 'token_model.g.dart';

@collection
class TokenModel {
  late Id key; // Custom unique student identifier with "G0" removed
  late int studentId;
  late String username; // Custom unique student identifier
  late String iss; // Institution id for student
  late String idToken; // Unique identifier for the token if needed
  late String accessToken; // The main auth token
  late String refreshToken; // Token used to refresh the access token
  late DateTime expiryDate;
  int? tokenVersion;
  int? updatedAtMs;

  TokenModel();

  factory TokenModel.fromValues(
    Id studentIdNorm,
    String studentId,
    String iss,
    String idToken,
    String accessToken,
    String refreshToken,
    int expiryDate, {
    int? tokenVersion,
    int? updatedAtMs,
  }) {
    var m = TokenModel();

    m.key = studentIdNorm;
    m.username = studentId;
    m.iss = iss;
    m.idToken = idToken;
    m.accessToken = accessToken;
    m.refreshToken = refreshToken;
    m.expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryDate);
    m.tokenVersion = tokenVersion;
    m.updatedAtMs = updatedAtMs;

    return m;
  }

  factory TokenModel.fromResp(TokenGrantResponse resp) {
    var m = TokenModel();
    final jwt = JWT.decode(resp.idToken);

    final payload = jwt.payload as Map<String, dynamic>;
    m.key = int.tryParse(
      "${payload["kreta:institute_code"].hashCode}${payload["kreta:institute_user_id"]}",
    )!;
    m.studentId =
        int.tryParse(payload["kreta:student_id"] ?? "") ?? // parent only field
        int.tryParse(payload["kreta:institute_user_id"])!;
    m.username = payload["kreta:user_name"];
    m.iss = payload["kreta:institute_code"];
    m.idToken = resp.idToken;
    m.accessToken = resp.accessToken;
    m.refreshToken = resp.refreshToken;
    m.expiryDate = DateTime.now()
        .add(Duration(seconds: resp.expiresIn))
        .subtract(Duration(minutes: 1)); // just to be safe
    final iat = payload["iat"];
    if (iat is int) {
      m.tokenVersion = iat * 1000;
    } else if (iat is String) {
      final parsed = int.tryParse(iat);
      if (parsed != null) {
        m.tokenVersion = parsed * 1000;
      }
    }
    m.updatedAtMs = DateTime.now().millisecondsSinceEpoch;

    return m;
  }
}
