import 'package:flutter_bloc/flutter_bloc.dart';

class WearSyncState {
  final bool isSyncing;

  const WearSyncState({this.isSyncing = false});
}

class WearSyncCubit extends Cubit<WearSyncState> {
  WearSyncCubit() : super(const WearSyncState());

  void setSyncing(bool value) {
    emit(WearSyncState(isSyncing: value));
  }
}
