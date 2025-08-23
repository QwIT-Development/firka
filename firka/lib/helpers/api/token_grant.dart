import 'package:dio/dio.dart';
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
