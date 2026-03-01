import 'package:isar_community/isar.dart';

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

  factory TokenModel.fromValues(
    Id studentIdNorm,
    studentId,
    String iss,
    String idToken,
    String accessToken,
    String refreshToken,
    int expiryDate,
  ) {
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
}
