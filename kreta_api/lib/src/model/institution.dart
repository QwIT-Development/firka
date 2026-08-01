import 'generic.dart';

class Institution extends UidObj {
  final CustomizationSettings customizationSettings;
  final String shortName;
  final List<SystemModule> systemModuleList;

  Institution({
    required this.customizationSettings,
    required this.shortName,
    required this.systemModuleList,
    required super.uid,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    var systemModuleList = List<SystemModule>.empty(growable: true);

    for (var item in json['Rendszermodulok']) {
      systemModuleList.add(SystemModule.fromJson(item));
    }

    return Institution(
      customizationSettings: CustomizationSettings.fromJson(
        json['TestreszabasBeallitasok'],
      ),
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

  const CustomizationSettings({
    required this.delayForNotifications,
    required this.isClassAverageVisible,
    required this.isLessonsThemeVisible,
    required this.nextServerDeployAsString,
  });

  factory CustomizationSettings.fromJson(Map<String, dynamic> json) {
    return CustomizationSettings(
      delayForNotifications:
          json['ErtekelesekMegjelenitesenekKesleltetesenekMerteke'],
      isClassAverageVisible: json['IsOsztalyAtlagMegjeleniteseEllenorzoben'],
      isLessonsThemeVisible: json['IsTanorakTemajaMegtekinthetoEllenorzoben'],
      nextServerDeployAsString: json['KovetkezoTelepitesDatuma'],
    );
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

  const SystemModule({
    required this.isActive,
    required this.type,
    required this.url,
  });

  factory SystemModule.fromJson(Map<String, dynamic> json) {
    return SystemModule(
      isActive: json['IsAktiv'],
      type: json['Tipus'],
      url: json['Url'],
    );
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
