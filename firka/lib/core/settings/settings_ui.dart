import "package:firka/ui/shared/firka_icon.dart";

import "setting.dart";

/// UI-only description of a settings screen: icons, titles, grouping, navigation,
/// visibility. Holds no values itself, only references to typed [Setting]s whose
/// values live in SettingsRepository. Separate from the data schema on purpose:
/// see AGENTS.md and the settings redesign plan for why.
sealed class SettingsUiNode {
  final bool Function() visible;

  const SettingsUiNode(this.visible);
}

class SettingsUiGroup extends SettingsUiNode {
  final List<SettingsUiNode> children;

  const SettingsUiGroup(this.children, bool Function() visible)
    : super(visible);
}

class SettingsUiPadding extends SettingsUiNode {
  final double padding;

  const SettingsUiPadding(this.padding, bool Function() visible)
    : super(visible);
}

class SettingsUiBackHeader extends SettingsUiNode {
  final String title;

  const SettingsUiBackHeader(this.title, bool Function() visible)
    : super(visible);
}

class SettingsUiHeader extends SettingsUiNode {
  final String title;

  const SettingsUiHeader(this.title, bool Function() visible) : super(visible);
}

class SettingsUiMediumHeader extends SettingsUiNode {
  final String title;

  const SettingsUiMediumHeader(this.title, bool Function() visible)
    : super(visible);
}

class SettingsUiHeaderSmall extends SettingsUiNode {
  final String title;

  const SettingsUiHeaderSmall(this.title, bool Function() visible)
    : super(visible);
}

class SettingsUiSubGroup extends SettingsUiNode {
  final FirkaIconType? iconType;
  final Object? iconData;
  final String title;
  final List<SettingsUiNode> children;
  final String? redirectTo;

  const SettingsUiSubGroup(
    this.iconType,
    this.iconData,
    this.title,
    this.children,
    bool Function() visible, [
    this.redirectTo,
  ]) : super(visible);
}

class SettingsUiBoolean extends SettingsUiNode {
  final FirkaIconType? iconType;
  final Object? iconData;
  final String title;
  final BoolSetting setting;

  const SettingsUiBoolean(
    this.iconType,
    this.iconData,
    this.title,
    this.setting,
    bool Function() visible,
  ) : super(visible);
}

class SettingsUiDouble extends SettingsUiNode {
  final FirkaIconType? iconType;
  final Object? iconData;
  final String title;
  final DoubleSetting setting;

  const SettingsUiDouble(
    this.iconType,
    this.iconData,
    this.title,
    this.setting,
    bool Function() visible,
  ) : super(visible);
}

class SettingsUiEnum extends SettingsUiNode {
  final EnumSetting setting;
  final List<String> optionLabels;

  const SettingsUiEnum(this.setting, this.optionLabels, bool Function() visible)
    : super(visible);
}

class SettingsUiButton extends SettingsUiNode {
  final FirkaIconType? iconType;
  final Object? iconData;
  final String title;
  final Future<void> Function() onTap;

  const SettingsUiButton(
    this.iconType,
    this.iconData,
    this.title,
    bool Function() visible,
    this.onTap,
  ) : super(visible);
}

class SettingsUiAppIconPreview extends SettingsUiNode {
  const SettingsUiAppIconPreview(super.visible);
}

class SettingsUiAppIconPicker extends SettingsUiNode {
  final Map<String, List<String>> iconGroups;
  final SettingsUiBoolean childProtection;

  const SettingsUiAppIconPicker(
    this.iconGroups,
    this.childProtection,
    bool Function() visible,
  ) : super(visible);
}

class SettingsUiKretaAccountPicker extends SettingsUiNode {
  const SettingsUiKretaAccountPicker(super.visible);
}

class SettingsUiLogs extends SettingsUiNode {
  const SettingsUiLogs(super.visible);
}

class SettingsUiLicensePage extends SettingsUiNode {
  const SettingsUiLicensePage(super.visible);
}
