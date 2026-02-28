import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeState {
  final bool isLightMode;

  const ThemeState({required this.isLightMode});
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({bool initialLightMode = true})
    : super(ThemeState(isLightMode: initialLightMode));

  void setLightMode(bool isLight) {
    emit(ThemeState(isLightMode: isLight));
  }

  void refresh() {
    emit(ThemeState(isLightMode: state.isLightMode));
  }
}
