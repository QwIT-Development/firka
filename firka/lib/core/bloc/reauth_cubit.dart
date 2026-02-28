import 'package:flutter_bloc/flutter_bloc.dart';

class ReauthState {
  final bool needsReauth;

  const ReauthState({this.needsReauth = false});
}

class ReauthCubit extends Cubit<ReauthState> {
  ReauthCubit() : super(const ReauthState());

  void setNeedsReauth(bool value) {
    emit(ReauthState(needsReauth: value));
  }

  void clear() {
    emit(const ReauthState(needsReauth: false));
  }
}
