import 'package:firka/helpers/api/consts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> isWear() async {
  const platform = MethodChannel('firka.app/main');

  return await platform.invokeMethod("isWear");
}

Future<bool> isPhone() async {
  return !(await isWear());
}

Future<void> resetAppData() async {
  final isarDir = await getApplicationDocumentsDirectory();
  if (await isarDir.exists()) await isarDir.delete(recursive: true);
}

void setApiUrls() {
  KretaEndpoints.kretaBase = "localhost:8060";
  KretaEndpoints.kretaIdp = "http://localhost:8060";
  KretaEndpoints.kretaLoginUrl =
      "${KretaEndpoints.kretaIdp}/Account/Login?ReturnUrl=%2Fconnect%2Fauthorize%2Fcallback%3Fprompt%3Dlogin%26nonce%3DwylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU%26response_type%3Dcode%26code_challenge_method%3DS256%26scope%3Dopenid%2520email%2520offline_access%2520kreta-ellenorzo-webapi.public%2520kreta-eugyintezes-webapi.public%2520kreta-fileservice-webapi.public%2520kreta-mobile-global-webapi.public%2520kreta-dkt-webapi.public%2520kreta-ier-webapi.public%26code_challenge%3DHByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ%26redirect_uri%3Dhttps%253A%252F%252Fmobil.e-kreta.hu%252Fellenorzo-student%252Fprod%252Foauthredirect%26client_id%3Dkreta-ellenorzo-student-mobile-ios%26state%3Dkreta_student_mobile%26suppressed_prompt%3Dlogin";
  KretaEndpoints.tokenGrantUrl = "${KretaEndpoints.kretaIdp}/connect/token";
}

Future<void> waitUntil(Duration timeout, WidgetTester tester,
    Future<bool> Function() callback) async {
  var now = DateTime.now();
  while (
      now.difference(DateTime.now()).inMilliseconds < timeout.inMilliseconds) {
    await tester.pump(Duration(milliseconds: 100));

    if (await callback()) {
      return;
    }
  }

  throw Exception("waitUntil timed out");
}
