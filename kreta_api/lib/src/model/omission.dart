import '../extensions.dart';
import 'generic.dart';
import 'subject.dart';

class Omission extends UidObj {
  final Subject subject;
  final OmittedLesson? lesson;
  final DateTime date;
  final String teacher;
  final NameUidDesc? type;
  final NameUidDesc? mode;
  final int? lateForMin;
  final DateTime createdAt;
  final OmissionState state;
  final NameUidDesc? proofType;
  final UidObj? classGroup;

  const Omission({
    required super.uid,
    required this.subject,
    required this.lesson,
    required this.date,
    required this.teacher,
    this.type,
    this.mode,
    this.lateForMin,
    required this.createdAt,
    required this.state,
    required this.proofType,
    this.classGroup,
  });

  factory Omission.fromJson(Map<String, dynamic> json) {
    return Omission(
      uid: json['Uid'],
      subject: Subject.fromJson(json['Tantargy']),
      lesson: json['Ora'] != null ? OmittedLesson.fromJson(json['Ora']) : null,
      date: json.localDate('Datum')!,
      teacher: json['RogzitoTanarNeve'],
      type: json.nameUidDesc('Tipus'),
      mode: json.nameUidDesc('Mod'),
      lateForMin: json['KesesPercben'],
      createdAt: json.localDate('KeszitesDatuma')!,
      state: OmissionState.fromString(json['IgazolasAllapota']),
      proofType: json.nameUidDesc('IgazolasTipusa'),
      classGroup: json.uid('OsztalyCsoport'),
    );
  }

  @override
  String toString() {
    return 'Omission('
        'uid: "$uid", '
        'subject: $subject, '
        'c: $lesson, '
        'date: $date, '
        'teacher: "$teacher", '
        'type: $type, '
        'mode: $mode, '
        'lateForMin: $lateForMin, '
        'createdAt: $createdAt, '
        'state: "$state", '
        'proofType: $proofType, '
        'classGroup: $classGroup'
        ')';
  }
}

enum OmissionState {
  excused("Igazolt"),
  unexcused("Igazolatlan"),
  pending("Igazolando"),
  unknown("");

  final String key;
  const OmissionState(this.key);

  static fromString(String string) {
    for (final state in OmissionState.values) {
      if (state.key == string) {
        return state;
      }
    }
    print("Unknown omission state: ${string}");
    return OmissionState.unknown;
  }
}

class OmittedLesson {
  final DateTime start;
  final DateTime end;
  final int? classNo;

  const OmittedLesson({
    required this.start,
    required this.end,
    required this.classNo,
  });

  factory OmittedLesson.fromJson(Map<String, dynamic> json) {
    return OmittedLesson(
      start: json.localDate('KezdoDatum')!,
      end: json.localDate('VegDatum')!,
      classNo: json['Oraszam'],
    );
  }

  @override
  String toString() {
    return 'OmittedLesson('
        'start: "$start", '
        'end: "$end", '
        'classNo: $classNo'
        ')';
  }
}
