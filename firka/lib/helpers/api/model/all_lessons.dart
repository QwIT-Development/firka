import 'dart:convert';

class AllLessons {
  final String intezmenyId;
  final String tanevId;
  final dynamic osztalyId;
  final String? osztalyNev;
  final bool osztalyMunkaTer;
  final dynamic csoportId;
  final String? csoportNev;
  final bool csoportMunkaTer;
  final String osztalyCsoportNev;
  final dynamic tantargyId;
  final String tantargyNev;
  final dynamic alkalmazottId;
  final String alkalmazottGuid;
  final String alkalmazottNev;
  final dynamic alkalmazottUzenoFalId;
  final dynamic uzenoFalId;
  final String? nyelvId;
  final dynamic tantargyKategoriaId;
  final String tantargyKategoriaNev;
  final dynamic tipusId;
  final String tipusNev;
  final dynamic evfolyamTipusId;
  final String evfolyamTipusNev;
  final dynamic feladatEllatasiHelyId;
  final String feladatEllatasiHelyNev;
  final dynamic alkalmazottAvatarTipusId;
  final String alkalmazottAvatarEleres;
  final dynamic oraiFeladatGroupId;

  AllLessons({
    required this.intezmenyId,
    required this.tanevId,
    this.osztalyId,
    this.osztalyNev,
    required this.osztalyMunkaTer,
    this.csoportId,
    this.csoportNev,
    required this.csoportMunkaTer,
    required this.osztalyCsoportNev,
    required this.tantargyId,
    required this.tantargyNev,
    required this.alkalmazottId,
    required this.alkalmazottGuid,
    required this.alkalmazottNev,
    this.alkalmazottUzenoFalId,
    this.uzenoFalId,
    this.nyelvId,
    required this.tantargyKategoriaId,
    required this.tantargyKategoriaNev,
    required this.tipusId,
    required this.tipusNev,
    required this.evfolyamTipusId,
    required this.evfolyamTipusNev,
    required this.feladatEllatasiHelyId,
    required this.feladatEllatasiHelyNev,
    required this.alkalmazottAvatarTipusId,
    required this.alkalmazottAvatarEleres,
    this.oraiFeladatGroupId,
  });

  factory AllLessons.fromJson(Map<String, dynamic> json) => AllLessons(
      intezmenyId: json['intezmenyId']?.toString() ?? '',
      tanevId: json['tanevId']?.toString() ?? '',
      osztalyId: json['osztalyId'],
      osztalyNev: json['osztalyNev']?.toString(),
      osztalyMunkaTer: json['osztalyMunkaTer'] == true,
      csoportId: json['csoportId'],
      csoportNev: json['csoportNev']?.toString(),
      csoportMunkaTer: json['csoportMunkaTer'] == true,
      osztalyCsoportNev: json['osztalyCsoportNev']?.toString() ?? '',
      tantargyId: json['tantargyId'],
      tantargyNev: json['tantargyNev']?.toString() ?? '',
      alkalmazottId: json['alkalmazottId'],
      alkalmazottGuid: json['alkalmazottGuid']?.toString() ?? '',
      alkalmazottNev: json['alkalmazottNev']?.toString() ?? '',
      alkalmazottUzenoFalId: json['alkalmazottUzenoFalId'],
      uzenoFalId: json['uzenoFalId'],
      nyelvId: json['nyelvId']?.toString(),
      tantargyKategoriaId: json['tantargyKategoriaId'],
      tantargyKategoriaNev: json['tantargyKategoriaNev']?.toString() ?? '',
      tipusId: json['tipusId'],
      tipusNev: json['tipusNev']?.toString() ?? '',
      evfolyamTipusId: json['evfolyamTipusId'],
      evfolyamTipusNev: json['evfolyamTipusNev']?.toString() ?? '',
      feladatEllatasiHelyId: json['feladatEllatasiHelyId'],
      feladatEllatasiHelyNev: json['feladatEllatasiHelyNev']?.toString() ?? '',
      alkalmazottAvatarTipusId: json['alkalmazottAvatarTipusId'],
      alkalmazottAvatarEleres: json['alkalmazottAvatarEleres']?.toString() ?? '',
      oraiFeladatGroupId: json['oraiFeladatGroupId'],
    );


  Map<String, dynamic> toJson() => {
        'intezmenyId': intezmenyId,
        'tanevId': tanevId,
        'osztalyId': osztalyId,
        'osztalyNev': osztalyNev,
        'osztalyMunkaTer': osztalyMunkaTer,
        'csoportId': csoportId,
        'csoportNev': csoportNev,
        'csoportMunkaTer': csoportMunkaTer,
        'osztalyCsoportNev': osztalyCsoportNev,
        'tantargyId': tantargyId,
        'tantargyNev': tantargyNev,
        'alkalmazottId': alkalmazottId,
        'alkalmazottGuid': alkalmazottGuid,
        'alkalmazottNev': alkalmazottNev,
        'alkalmazottUzenoFalId': alkalmazottUzenoFalId,
        'uzenoFalId': uzenoFalId,
        'nyelvId': nyelvId,
        'tantargyKategoriaId': tantargyKategoriaId,
        'tantargyKategoriaNev': tantargyKategoriaNev,
        'tipusId': tipusId,
        'tipusNev': tipusNev,
        'evfolyamTipusId': evfolyamTipusId,
        'evfolyamTipusNev': evfolyamTipusNev,
        'feladatEllatasiHelyId': feladatEllatasiHelyId,
        'feladatEllatasiHelyNev': feladatEllatasiHelyNev,
        'alkalmazottAvatarTipusId': alkalmazottAvatarTipusId,
        'alkalmazottAvatarEleres': alkalmazottAvatarEleres,
        'oraiFeladatGroupId': oraiFeladatGroupId,
      };
}

List<AllLessons> lessonsFromJson(String str) =>
    List<AllLessons>.from(json.decode(str).map((x) => AllLessons.fromJson(x)));

String lessonsToJson(List<AllLessons> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));