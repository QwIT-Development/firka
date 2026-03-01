/// URL builders for Kreta ellenorzo API that depend only on [iss].
/// Auth-related URLs (login, token) and Constants stay in the app (firka).
class KretaEndpoints {
  static const String kretaBase = "e-kreta.hu";

  static String kreta(String iss) {
    if (iss == "firka-test") {
      return kretaBase;
    } else {
      return "https://$iss.$kretaBase";
    }
  }

  static String getStudentUrl(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/TanuloAdatlap";

  static String getClassGroups(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/OsztalyCsoportok";

  static String getNoticeBoard(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/FaliujsagElemek";

  static String getInfoBoard(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Feljegyzesek";

  static String getGrades(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek";

  static String getSubjectAvg(String iss, String studyGroupId) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Ertekelesek/Atlagok/TantargyiAtlagok?oktatasiNevelesiFeladatUid=$studyGroupId&oktatasiNevelesiFeladatUid=$studyGroupId";

  static String getTimeTable(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/OrarendElemek";

  static String getOmissions(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/Mulasztasok";

  static String getHomework(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/HaziFeladatok";

  static String getTests(String iss) =>
      "${kreta(iss)}/ellenorzo/v3/sajat/BejelentettSzamonkeresek";

  static String getLessons(String iss) =>
      "${kreta(iss)}/dktapi/intezmenyek/munkaterek/tanulok";
}
