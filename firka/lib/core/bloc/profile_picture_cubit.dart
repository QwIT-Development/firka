import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePictureState {
  final int version;

  const ProfilePictureState({this.version = 0});
}

class ProfilePictureCubit extends Cubit<ProfilePictureState> {
  ProfilePictureCubit() : super(const ProfilePictureState());

  void notifyChanged() {
    emit(ProfilePictureState(version: state.version + 1));
  }
}
