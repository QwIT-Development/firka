import 'package:intl/intl.dart';

/// URL builders for Kreta ellenorzo API that depend only on [iss].
/// Auth-related URLs (login, token) and Constants stay in the app (firka).
class KretaEndpoints {
  static const String kretaBase = "e-kreta.hu";
  static DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd');

  static String kreta(String iss) {
    if (iss == "firka-test") {
      return kretaBase;
    } else {
      return "https://$iss.$kretaBase";
    }
  }

  static String dateQuery(DateTime? from, DateTime? to) {
    StringBuffer buffer = StringBuffer();

    if (from == null) {
      if (to == null) {
        return buffer.toString();
      }
      throw Exception("'from' is required to use 'to'");
    }

    buffer.write("?datumTol=");
    buffer.write(dateTimeFormat.format(from));

    if (to != null) {
      buffer.write("&datumIg=");
      buffer.write(dateTimeFormat.format(to));
    }
    return buffer.toString();
  }

  static String getStudentUrl(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/TanuloAdatlap";

  static String getClassGroups(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/OsztalyCsoportok";

  static String getNoticeBoard(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/FaliujsagElemek${dateQuery(from, to)}";

  static String getInfoBoard(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Feljegyzesek${dateQuery(from, to)}";

  static String getGrades(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek${dateQuery(from, to)}";

  static String getSubjectAvg(String iss, String studyGroupId) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek/Atlagok/TantargyiAtlagok?oktatasiNevelesiFeladatUid=$studyGroupId&oktatasiNevelesiFeladatUid=$studyGroupId";

  static String getClassGroupAvg(String iss, String studyGroupId) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek/Atlagok/OsztalyAtlagok?oktatasiNevelesiFeladatUid=$studyGroupId&oktatasiNevelesiFeladatUid=$studyGroupId";

  static String getTimeTable(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/OrarendElemek${dateQuery(from, to)}";

  static String getOmissions(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Mulasztasok${dateQuery(from, to)}";

  static String getHomework(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/HaziFeladatok${dateQuery(from, to)}";

  static String getTests(String iss, [DateTime? from, DateTime? to]) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/BejelentettSzamonkeresek${dateQuery(from, to)}";

  static String getLessons(String iss) =>
      "${kreta(iss)}/dktapi/intezmenyek/munkaterek/tanulok";
}
