import 'package:dio/dio.dart';
import 'package:firka/helpers/api/exceptions/token.dart';
import 'package:firka/helpers/api/resp/token_grant.dart';
import 'package:firka/helpers/db/models/token_model.dart';

import '../../main.dart';
import 'consts.dart';

Future<TokenGrantResponse> getAccessToken(String code) async {
  final headers = <String, String>{
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "accept": "*/*",
    "user-agent": Constants.userAgent,
  };

  final formData = <String, String>{
    "code": code,
    "code_verifier": KretaEndpoints.codeVerifier,
    "redirect_uri":
        "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect",
    "client_id": Constants.clientId,
    "grant_type": "authorization_code",
  };

  try {
    final response = await dio.post(KretaEndpoints.tokenGrantUrl,
        options: Options(headers: headers), data: formData);

    switch (response.statusCode) {
      case 200:
        return TokenGrantResponse.fromJson(response.data);
      case 401:
        throw Exception("Invalid grant");
      default:
        throw Exception(
            "Failed to get access token, response code: ${response.statusCode}");
    }
  } catch (e) {
    rethrow;
  }
}

Future<TokenGrantResponse> extendToken(TokenModel model) async {
  logger.info("Extending token for user: ${model.studentId}, institute: ${model.iss}");

  final headers = <String, String>{
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "accept": "*/*",
    "user-agent": Constants.userAgent,
  };

  final formData = <String, String>{
    "institute_code": model.iss!,
    "refresh_token": model.refreshToken!,
    "grant_type": "refresh_token",
    "client_id": Constants.clientId,
  };

  try {
    final response = await dio.post(KretaEndpoints.tokenGrantUrl,
        options: Options(headers: headers), data: formData);

    switch (response.statusCode) {
      case 200:
        logger.info("Token extended successfully for user: ${model.studentId}");
        return TokenGrantResponse.fromJson(response.data);
      case 400:
        logger.warning("Token refresh failed (400) - refresh token expired for user: ${model.studentId}");
        throw TokenExpiredException();
      case 401:
        logger.warning("Token refresh failed (401) - invalid grant for user: ${model.studentId}");
        throw InvalidGrantException();
      default:
        logger.severe("Token refresh failed with unexpected status: ${response.statusCode} for user: ${model.studentId}");
        throw Exception(
            "Failed to get access token, response code: ${response.statusCode}");
    }
  } catch (e) {
    logger.severe("Token refresh exception for user: ${model.studentId}: $e");
    rethrow;
  }
}
