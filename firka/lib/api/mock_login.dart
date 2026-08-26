import "package:dio/dio.dart";
import "package:firka_common/core/consts.dart";

import "package:firka/app/app_state.dart";
import "package:firka/core/dev/mock_backend.dart";
import "package:kreta_api/kreta_api.dart";

Future<TokenGrantResponse> mockLogin(String username, String password) async {
  final headers = <String, String>{
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "accept": "*/*",
    "user-agent": initData.userAgent,
  };

  final formData = <String, String>{
    "grant_type": "password",
    "username": username,
    "password": password,
    "client_id": Constants.clientId,
  };

  final response = await dio.post(
    MockBackend.rewrite(KretaLoginEndpoints.tokenGrantUrl),
    options: Options(headers: headers),
    data: formData,
  );

  switch (response.statusCode) {
    case 200:
      return TokenGrantResponse.fromJson(response.data);
    case 401:
      throw Exception("Invalid credentials");
    default:
      throw Exception(
        "Failed to get access token, response code: ${response.statusCode}",
      );
  }
}
