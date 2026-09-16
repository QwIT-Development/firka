import 'package:firka_common/core/icon_helper.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getIconType - Software development (ClassIcon.applications)', () {
    void checkSubject(String name, dynamic expected) {
      final subject = SubjectCacheModel()..name = name;
      expect(getIconType(subject), expected, reason: 'Failed for "$name"');
    }

    test('matches variations of Asztali és mobil alk', () {
      checkSubject('Asztali és mobil alk', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil alk.', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil alkalmazások', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil alkalmazások fejlesztése', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil alkalmazásfejlesztés', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil alk. fej.', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil fej.', equals(ClassIcon.applications));
      checkSubject('Asztali és mobil', equals(ClassIcon.applications));
      checkSubject('Asztali és mob alk', equals(ClassIcon.applications));
      checkSubject('Asztali alk.', equals(ClassIcon.applications));
      checkSubject('Asztali alk', equals(ClassIcon.applications));
      checkSubject('Asztali alkalmazások', equals(ClassIcon.applications));
      checkSubject('Asztali- és mobilalkalmazások', equals(ClassIcon.applications));
      checkSubject('Asztali-mobil alk.', equals(ClassIcon.applications));
    });

    test('matches mobile application development variations', () {
      checkSubject('Mobil alk.', equals(ClassIcon.applications));
      checkSubject('Mobil alk', equals(ClassIcon.applications));
      checkSubject('Mobil alkalmazások', equals(ClassIcon.applications));
      checkSubject('Mobilalkalmazások', equals(ClassIcon.applications));
      checkSubject('Mobil app', equals(ClassIcon.applications));
      checkSubject('Mobilfejlesztés', equals(ClassIcon.applications));
      checkSubject('Mobil programozás', equals(ClassIcon.applications));
    });

    test('matches software development variations', () {
      checkSubject('Szoftverfejlesztés', equals(ClassIcon.applications));
      checkSubject('Szoftverfejlesztés és tesztelés', equals(ClassIcon.applications));
      checkSubject('Szoftverfejlesztő', equals(ClassIcon.applications));
      checkSubject('Szoftvertesztelés', equals(ClassIcon.applications));
      checkSubject('Software development', equals(ClassIcon.applications));
      checkSubject('Software dev', equals(ClassIcon.applications));
    });

    test('does not misclassify asztalitenisz as applications', () {
      checkSubject('Asztalitenisz', isNot(equals(ClassIcon.applications)));
      checkSubject('Asztali tenisz', isNot(equals(ClassIcon.applications)));
    });
  });

  group('getIconType - Language / Szakmai angol / Idegen nyelv (ClassIcon.language)', () {
    void checkSubject(String name, dynamic expected) {
      final subject = SubjectCacheModel()..name = name;
      expect(getIconType(subject), expected, reason: 'Failed for "$name"');
    }

    test('matches multiple ways of shortening idegen nyelv', () {
      checkSubject('id.ny.', equals(ClassIcon.language));
      checkSubject('id. ny.', equals(ClassIcon.language));
      checkSubject('id.ny', equals(ClassIcon.language));
      checkSubject('id ny', equals(ClassIcon.language));
      checkSubject('idny', equals(ClassIcon.language));
      checkSubject('id-ny', equals(ClassIcon.language));
      checkSubject('ID.NY.', equals(ClassIcon.language));
      checkSubject('ID. NY.', equals(ClassIcon.language));
      checkSubject('ID NY', equals(ClassIcon.language));
      checkSubject('IDNY', equals(ClassIcon.language));
      checkSubject('id. nyelv', equals(ClassIcon.language));
      checkSubject('id.nyelv', equals(ClassIcon.language));
      checkSubject('id nyelv', equals(ClassIcon.language));
      checkSubject('idegen ny.', equals(ClassIcon.language));
      checkSubject('idegen ny', equals(ClassIcon.language));
      checkSubject('ideg. ny.', equals(ClassIcon.language));
      checkSubject('ideg.ny.', equals(ClassIcon.language));
      checkSubject('idegen nyelv', equals(ClassIcon.language));
      checkSubject('idegennyelv', equals(ClassIcon.language));
      checkSubject('idegen nyelvi', equals(ClassIcon.language));
    });

    test('matches Munkavállalói foreign language / szakmai angol variations', () {
      checkSubject('Munkavállalói id.ny.', equals(ClassIcon.language));
      checkSubject('Munkavállalói ID.NY.', equals(ClassIcon.language));
      checkSubject('Munkavállalói id. ny.', equals(ClassIcon.language));
      checkSubject('Munkavállalói id ny', equals(ClassIcon.language));
      checkSubject('Munkavállalói idny', equals(ClassIcon.language));
      checkSubject('Munkavállalói id.', equals(ClassIcon.language));
      checkSubject('Munkavállalói idegen ny.', equals(ClassIcon.language));
      checkSubject('Munkavállalói idegen nyelv', equals(ClassIcon.language));
      checkSubject('Munkavállalói idegennyelv', equals(ClassIcon.language));
      checkSubject('Munkavállalói angol', equals(ClassIcon.language));
      checkSubject('Munkavállalói német', equals(ClassIcon.language));
      checkSubject('Munkavallaloi id.ny.', equals(ClassIcon.language));
      checkSubject('Munkavállaló id.ny.', equals(ClassIcon.language));
      checkSubject('Munkavállaló id. ny.', equals(ClassIcon.language));
      checkSubject('Munkavállaló idegen nyelv', equals(ClassIcon.language));
      checkSubject('Munkavállaló idegen ny.', equals(ClassIcon.language));
      checkSubject('Munkavállaló id.', equals(ClassIcon.language));
      checkSubject('Munkavallalo id.ny.', equals(ClassIcon.language));
    });

    test('matches Szakmai idegen nyelv variations', () {
      checkSubject('Szakmai id.ny.', equals(ClassIcon.language));
      checkSubject('Szakmai id. ny.', equals(ClassIcon.language));
      checkSubject('Szakmai ID.NY.', equals(ClassIcon.language));
      checkSubject('Szakmai idegen nyelv', equals(ClassIcon.language));
      checkSubject('Szakmai idegen ny.', equals(ClassIcon.language));
      checkSubject('Szakmai angol', equals(ClassIcon.language));
      checkSubject('Szakmai német', equals(ClassIcon.language));
      checkSubject('Szakmai nyelv', equals(ClassIcon.language));
      checkSubject('Szakmai ny.', equals(ClassIcon.language));
      checkSubject('Szakmai ny', equals(ClassIcon.language));
    });

    test('does not misclassify non-language subjects', () {
      checkSubject('Munkavállalói ismeretek', isNull);
      checkSubject('Magyar nyelv', equals(ClassIcon.grammar));
    });
  });
}
