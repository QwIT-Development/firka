import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsState {
  final int version;

  const SettingsState({this.version = 0});
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void notifyChanged() {
    emit(SettingsState(version: state.version + 1));
  }
}
