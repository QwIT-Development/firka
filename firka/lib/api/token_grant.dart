import 'package:dio/dio.dart';
import 'package:firka/api/exceptions/token.dart';
import 'package:firka/api/resp/token_grant.dart';
import 'package:firka/data/models/token_model.dart';

import 'package:firka/app/app_state.dart';
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
    final response = await dio.post(
      KretaEndpoints.tokenGrantUrl,
      options: Options(headers: headers),
      data: formData,
    );

    switch (response.statusCode) {
      case 200:
        return TokenGrantResponse.fromJson(response.data);
      case 401:
        throw Exception("Invalid grant");
      default:
        throw Exception(
          "Failed to get access token, response code: ${response.statusCode}",
        );
    }
  } catch (e) {
    rethrow;
  }
}

const _tokenRefreshRetryDelays = [1000, 3000, 5000];

Future<TokenGrantResponse> extendToken(TokenModel model) async {
  logger.info(
    "Extending token for user: ${model.studentId}, institute: ${model.iss}",
  );

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

  Exception? lastError;

  for (int attempt = 0; attempt <= _tokenRefreshRetryDelays.length; attempt++) {
    try {
      if (attempt > 0) {
        final delay = _tokenRefreshRetryDelays[attempt - 1];
        logger.info(
          "Token refresh attempt ${attempt + 1}, waiting ${delay}ms...",
        );
        await Future.delayed(Duration(milliseconds: delay));
      }

      final response = await dio.post(
        KretaEndpoints.tokenGrantUrl,
        options: Options(headers: headers),
        data: formData,
      );

      switch (response.statusCode) {
        case 200:
          logger.info(
            "Token extended successfully for user: ${model.studentId}",
          );
          return TokenGrantResponse.fromJson(response.data);
        case 400:
        case 401:
          logger.warning(
            "Token refresh failed (${response.statusCode}) - refresh token invalid for user: ${model.studentId}",
          );
          throw response.statusCode == 400
              ? TokenExpiredException()
              : InvalidGrantException();
        default:
          logger.warning(
            "Token refresh failed (${response.statusCode}) for user: ${model.studentId}, attempt ${attempt + 1}",
          );
          lastError = Exception(
            "Failed to get access token, response code: ${response.statusCode}",
          );
          // Continue to retry for network errors
          continue;
      }
    } on TokenExpiredException {
      rethrow;
    } on InvalidGrantException {
      rethrow;
    } on DioException catch (e) {
      logger.warning(
        "Token refresh network error for user: ${model.studentId}, attempt ${attempt + 1}: $e",
      );
      lastError = e;
      continue;
    } catch (e) {
      logger.severe("Token refresh exception for user: ${model.studentId}: $e");
      lastError = e is Exception ? e : Exception(e.toString());
      continue;
    }
  }

  logger.severe(
    "All token refresh attempts failed for user: ${model.studentId}",
  );
  throw lastError ?? Exception("Token refresh failed after all retries");
}
