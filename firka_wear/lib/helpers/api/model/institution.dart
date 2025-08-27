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

class Institution {
  final CustomizationSettings customizationSettings;
  final String shortName;
  final List<SystemModule> systemModuleList;
  final String uid;

  Institution(
      {required this.customizationSettings,
      required this.shortName,
      required this.systemModuleList,
      required this.uid});

  factory Institution.fromJson(Map<String, dynamic> json) {
    var systemModuleList = List<SystemModule>.empty(growable: true);

    for (var item in json['Rendszermodulok']) {
      systemModuleList.add(SystemModule.fromJson(item));
    }

    return Institution(
      customizationSettings:
          CustomizationSettings.fromJson(json['TestreszabasBeallitasok']),
      shortName: json['RovidNev'],
      systemModuleList: systemModuleList,
      uid: json['Uid'],
    );
  }
}

class CustomizationSettings {
  final int delayForNotifications;
  final bool isClassAverageVisible;
  final bool isLessonsThemeVisible;
  final String nextServerDeployAsString;

  CustomizationSettings(
      {required this.delayForNotifications,
      required this.isClassAverageVisible,
      required this.isLessonsThemeVisible,
      required this.nextServerDeployAsString});

  factory CustomizationSettings.fromJson(Map<String, dynamic> json) {
    return CustomizationSettings(
        delayForNotifications:
            json['ErtekelesekMegjelenitesenekKesleltetesenekMerteke'],
        isClassAverageVisible: json['IsOsztalyAtlagMegjeleniteseEllenorzoben'],
        isLessonsThemeVisible: json['IsTanorakTemajaMegtekinthetoEllenorzoben'],
        nextServerDeployAsString: json['KovetkezoTelepitesDatuma']);
  }

  @override
  String toString() {
    return 'CustomizationSettings('
        'delayForNotifications: $delayForNotifications, '
        'isClassAverageVisible: $isClassAverageVisible, '
        'isLessonsThemeVisible: $isLessonsThemeVisible, '
        'nextServerDeployAsString: "$nextServerDeployAsString"'
        ')';
  }
}

class SystemModule {
  final bool isActive;
  final String type;
  final String? url;

  SystemModule({required this.isActive, required this.type, required this.url});

  factory SystemModule.fromJson(Map<String, dynamic> json) {
    return SystemModule(
        isActive: json['IsAktiv'], type: json['Tipus'], url: json['Url']);
  }

  @override
  String toString() {
    return 'SystemModule('
        'isActive: $isActive, '
        'type: "$type", '
        'url: "$url"'
        ')';
  }
}
