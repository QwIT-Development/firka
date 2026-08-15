import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:logging/logging.dart";

import "package:firka/core/settings/settings_repository.dart";
import "package:firka/core/settings/settings_schema.dart";

final Logger _logger = Logger('AppIconPickerCubit');

class AppIconPickerState {
  final String activeIcon;
  final bool saving;

  const AppIconPickerState({required this.activeIcon, this.saving = false});

  AppIconPickerState copyWith({String? activeIcon, bool? saving}) =>
      AppIconPickerState(
        activeIcon: activeIcon ?? this.activeIcon,
        saving: saving ?? this.saving,
      );
}

class AppIconPickerCubit extends Cubit<AppIconPickerState> {
  AppIconPickerCubit(String initialIcon)
    : super(AppIconPickerState(activeIcon: initialIcon));

  void select(String icon) {
    if (state.saving) return;
    emit(state.copyWith(activeIcon: icon));
  }

  /// Persists the selected icon and swaps the platform's launcher icon.
  Future<void> save(List<String> allIconKeys) async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));

    await Settings.appIcon.set(state.activeIcon);

    await Future.delayed(Duration(seconds: 1));

    _logger.info(allIconKeys.join(","));
    _logger.info(state.activeIcon);

    const channel = MethodChannel('firka.app/main');
    _logger.info(
      await channel.invokeMethod('set_icon', {
        "icon": state.activeIcon == "original" ? null : state.activeIcon,
        "icons": allIconKeys.join(","),
      }),
    );
  }
}
