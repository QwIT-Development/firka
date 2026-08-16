import 'dart:typed_data';

import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

enum ClassIcon {
  mathematics,
  grammar,
  literature,
  history,
  geography,
  art,
  physics,
  music,
  pe,
  chemistry,
  biology,
  env,
  religion,
  economics,
  it,
  code,
  networking,
  theatre,
  film,
  electricalEngineering,
  mechanicalEngineering,
  technika,
  dance,
  philosophy,
  erettsegi,
  ofo,
  diligence,
  attitude,
  language,
  linux,
  database,
  applications,
  project,
}

Map<ClassIcon, RegExp> _descriptors = {
  ClassIcon.mathematics: RegExp(r'mate(k|matika)'),
  ClassIcon.grammar: RegExp(r'magyar nyelv|nyelvtan'),
  ClassIcon.literature: RegExp(r'irodalom'),
  ClassIcon.history: RegExp(r'tor(i|tenelem)'),
  ClassIcon.geography: RegExp(r'foldrajz'),
  ClassIcon.art: RegExp(r'rajz|muvtori|muveszet|vizualis'),
  ClassIcon.physics: RegExp(r'fizika'),
  ClassIcon.music: RegExp(r'^enek|zene|szolfezs|zongora|korus'),
  ClassIcon.pe: RegExp(r'^tes(i|tneveles)|sport|edzeselmelet'),
  ClassIcon.chemistry: RegExp(r'kemia'),
  ClassIcon.biology: RegExp(r'biologia'),
  ClassIcon.env: RegExp(
    r'kornyezet|termeszet ?(tudomany|ismeret)|hon( es nep)?ismeret',
  ),
  ClassIcon.religion: RegExp(r'(hit|erkolcs)tan|vallas|etika|bibliaismeret'),
  ClassIcon.economics: RegExp(r'penzugy|gazdasag'),
  ClassIcon.it: RegExp(r'informatika|szoftver|iroda|digitalis'),
  ClassIcon.code: RegExp(r'prog|alkalmazas'),
  ClassIcon.networking: RegExp(r'halozat'),
  ClassIcon.theatre: RegExp(r'szinhaz'),
  ClassIcon.film: RegExp(r'film|media'),
  ClassIcon.electricalEngineering: RegExp(r'elektro(tech)?nika'),
  ClassIcon.mechanicalEngineering: RegExp(r'gepesz|mernok|ipar'),
  ClassIcon.technika: RegExp(r'technika'),
  ClassIcon.dance: RegExp(r'tanc'),
  ClassIcon.philosophy: RegExp(r'filozofia'),
  ClassIcon.erettsegi: RegExp(r'erettsegi'),
  ClassIcon.ofo: RegExp(r'osztaly(fonoki|kozosseg)|kozossegi|neveles'),
  ClassIcon.diligence: RegExp(r'szorgalom'),
  ClassIcon.attitude: RegExp(r'magatartas'),
  ClassIcon.language: RegExp(
    r'angol|nemet|francia|olasz|orosz|spanyol|latin|kinai|nyelv',
  ),
  ClassIcon.linux: RegExp(r'linux'),
  ClassIcon.database: RegExp(r'adatbazis.*'),
  ClassIcon.applications: RegExp(r'asztali alkalmazasok'),
  ClassIcon.project: RegExp(r'projekt'),
};

Map<ClassIcon, Uint8List> _iconMap = {
  ClassIcon.mathematics: Majesticon.calculatorSolid,
  ClassIcon.grammar: Majesticon.bookSolid,
  ClassIcon.literature: Majesticon.bookOpenSolid,
  ClassIcon.history: Majesticon.compass2Solid,
  ClassIcon.geography: Majesticon.globeEarth2Solid,
  ClassIcon.art: Majesticon.editPen2Solid,
  ClassIcon.physics: Majesticon.atom2Solid,
  ClassIcon.music: Majesticon.musicNoteSolid,
  ClassIcon.pe: Majesticon.pulseSolid,
  ClassIcon.chemistry: Majesticon.testTubeFilledSolid,
  ClassIcon.biology: Majesticon.covidSolid,
  ClassIcon.env: Majesticon.leaf3AngledSolid,
  ClassIcon.religion: Majesticon.churchSolid,
  ClassIcon.economics: Majesticon.coinsSolid,
  ClassIcon.it: Majesticon.laptopSolid,
  ClassIcon.code: Majesticon.curlyBracesSolid,
  ClassIcon.networking: Majesticon.cloudSolid,
  ClassIcon.theatre: Majesticon.presentationPlaySolid,
  ClassIcon.film: Majesticon.videoSolid,
  ClassIcon.electricalEngineering: Majesticon.lightningBoltSolid,
  ClassIcon.mechanicalEngineering: Majesticon.settingsCogSolid,
  ClassIcon.technika: Majesticon.ruler2Solid,
  ClassIcon.dance: Majesticon.pinwheelSolid,
  ClassIcon.philosophy: Majesticon.lightbulbShineSolid,
  ClassIcon.erettsegi: Majesticon.awardSolid,
  ClassIcon.ofo: Majesticon.usersSolid,
  ClassIcon.diligence: Majesticon.clipboardCheckSolid,
  ClassIcon.attitude: Majesticon.userSolid,
  ClassIcon.language: Majesticon.tooltipsSolid,
  ClassIcon.linux: Majesticon.robotSolid,
  ClassIcon.database: Majesticon.dataSolid,
  ClassIcon.applications: Majesticon.monitorSolid,
  ClassIcon.project: Majesticon.presentationSolid,
};

ClassIcon? getIconType(SubjectCacheModel subject) {
  ClassIcon? icon;

  for (var desc in _descriptors.entries) {
    if (desc.value.hasMatch(
      subject.name
          .replaceAll("ö", "o")
          .replaceAll("ü", "u")
          .replaceAll("ó", "o")
          .replaceAll("ő", "o")
          .replaceAll("ú", "u")
          .replaceAll("é", "e")
          .replaceAll("á", "a")
          .replaceAll("ű", "u")
          .replaceAll("í", "i")
          .toLowerCase(),
    )) {
      icon = desc.key;

      break;
    }
  }

  return icon;
}

Uint8List getIconData(ClassIcon? icon) {
  if (icon == null) return Majesticon.alertCircleSolid;

  var iconData = _iconMap[icon];
  iconData ??= Majesticon.alertCircleSolid;

  return iconData;
}
