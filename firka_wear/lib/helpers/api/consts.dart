/*
  Firka, alternative e-Kréta client.
  Copyright (C) 2025  QwIT Development

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

class Constants {
  static const clientId = "kreta-ellenorzo-student-mobile-ios";
}

class KretaEndpoints {
  static String kretaBase = "e-kreta.hu";
  static String kreta(String iss) {
    if (iss == "firka-test") {
      return kretaBase;
    } else {
      return "https://$iss.$kretaBase";
    }
  }

  static String kretaIdp = "https://idp.e-kreta.hu";
  static String kretaLoginUrl =
      "$kretaIdp/Account/Login?ReturnUrl=%2Fconnect%2Fauthorize%2Fcallback%3Fprompt%3Dlogin%26nonce%3DwylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU%26response_type%3Dcode%26code_challenge_method%3DS256%26scope%3Dopenid%2520email%2520offline_access%2520kreta-ellenorzo-webapi.public%2520kreta-eugyintezes-webapi.public%2520kreta-fileservice-webapi.public%2520kreta-mobile-global-webapi.public%2520kreta-dkt-webapi.public%2520kreta-ier-webapi.public%26code_challenge%3DHByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ%26redirect_uri%3Dhttps%253A%252F%252Fmobil.e-kreta.hu%252Fellenorzo-student%252Fprod%252Foauthredirect%26client_id%3Dkreta-ellenorzo-student-mobile-ios%26state%3Dkreta_student_mobile%26suppressed_prompt%3Dlogin";
  static String tokenGrantUrl = "$kretaIdp/connect/token";

  static String getStudentUrl(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/TanuloAdatlap";
  static String getNoticeBoard(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/FaliujsagElemek";
  static String getGrades(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek";
  static String getTimeTable(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/OrarendElemek";
  static String getOmissions(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Mulasztasok";
  static String getHomework(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/HaziFeladatok";
  static String getTests(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/BejelentettSzamonkeresek";
}
