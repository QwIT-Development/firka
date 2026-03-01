import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firka/app/app_state.dart';
import 'package:kreta_api/kreta_api.dart' as ka;

class Constants {
  static String get clientId {
    if (Platform.isAndroid) {
      return "kreta-ellenorzo-student-mobile-android";
    } else {
      return "kreta-ellenorzo-student-mobile-ios";
    }
  }

  static const applicationId = "hu.ekreta.student";
  static const applicationVersion = "5.7.0";

  static String get userAgent {
    if (Platform.isAndroid) {
      return "$applicationId/$applicationVersion"
          "/${initData.devInfo.model}"
          "/${initData.devInfo.versionRelease}"
          "/${initData.devInfo.versionSdkInt}";
    } else {
      return "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0";
    }
  }
}

class OmissionConsts {
  static const present = "Jelenlet";
  static const absence = "Hianyzas";
  static const na = "Na";
}

class TimetableConsts {
  static const event = "TanevRendjeEsemeny";
}

class KretaEndpoints {
  static String _generateCodeVerifier() {
    var random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String generateStateOrNonce([int length = 16]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String kreta(String iss) => ka.KretaEndpoints.kreta(iss);

  static final String codeVerifier = _generateCodeVerifier();
  static final String _codeChallenge = _generateCodeChallenge(codeVerifier);
  static final String stateOrNonce = generateStateOrNonce();
  static final String clientId = Constants.clientId;

  static String kretaIdp = "https://idp.e-kreta.hu";
  static String kretaLoginUrl =
      "$kretaIdp/Account/Login?ReturnUrl=%2Fconnect%2Fauthorize%2Fcallback%3Fredirect_uri%3Dhttps%253A%252F%252Fmobil.e-kreta.hu%252Fellenorzo-student%252Fprod%252Foauthredirect%26client_id%3D$clientId%26response_type%3Dcode%26prompt%3Dlogin%26state%3D$stateOrNonce%26nonce%3D$stateOrNonce%26scope%3Dopenid%2520email%2520offline_access%2520kreta-ellenorzo-webapi.public%2520kreta-eugyintezes-webapi.public%2520kreta-fileservice-webapi.public%2520kreta-mobile-global-webapi.public%2520kreta-dkt-webapi.public%2520kreta-ier-webapi.public%26code_challenge%3D$_codeChallenge%26code_challenge_method%3DS256%26suppressed_prompt%3Dlogin";

  static String kretaLoginUrlRefresh(String username, String schoolId) =>
      "$kretaIdp/Account/Login?ReturnUrl=%2Fconnect%2Fauthorize%2Fcallback%3Fredirect_uri%3Dhttps%253A%252F%252Fmobil.e-kreta.hu%252Fellenorzo-student%252Fprod%252Foauthredirect%26client_id%3D$clientId%26response_type%3Dcode%26login_hint%3D$username%26prompt%3Dlogin%26state%3D$stateOrNonce%26nonce%3D$stateOrNonce%26scope%3Dopenid%2520email%2520offline_access%2520kreta-ellenorzo-webapi.public%2520kreta-eugyintezes-webapi.public%2520kreta-fileservice-webapi.public%2520kreta-mobile-global-webapi.public%2520kreta-dkt-webapi.public%2520kreta-ier-webapi.public%26code_challenge%3D$_codeChallenge%26code_challenge_method%3DS256%26institute_code%3D$schoolId%26suppressed_prompt%3Dlogin";
  static String tokenGrantUrl = "$kretaIdp/connect/token";

  static String getStudentUrl(String iss) =>
      ka.KretaEndpoints.getStudentUrl(iss);

  static String getClassGroups(String iss) =>
      ka.KretaEndpoints.getClassGroups(iss);

  static String getNoticeBoard(String iss) =>
      ka.KretaEndpoints.getNoticeBoard(iss);

  static String getInfoBoard(String iss) => ka.KretaEndpoints.getInfoBoard(iss);

  static String getGrades(String iss) => ka.KretaEndpoints.getGrades(iss);

  static String getSubjectAvg(String iss, String studyGroupId) =>
      ka.KretaEndpoints.getSubjectAvg(iss, studyGroupId);

  static String getTimeTable(String iss) => ka.KretaEndpoints.getTimeTable(iss);

  static String getOmissions(String iss) => ka.KretaEndpoints.getOmissions(iss);

  static String getHomework(String iss) => ka.KretaEndpoints.getHomework(iss);

  static String getTests(String iss) => ka.KretaEndpoints.getTests(iss);

  static String getLessons(String iss) => ka.KretaEndpoints.getLessons(iss);
}
