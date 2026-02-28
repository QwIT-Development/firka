import 'package:flutter_bloc/flutter_bloc.dart';

class HomeRefreshState {
  final int refreshTrigger;

  const HomeRefreshState({this.refreshTrigger = 0});
}

class HomeRefreshCubit extends Cubit<HomeRefreshState> {
  HomeRefreshCubit() : super(const HomeRefreshState());

  void requestRefresh() {
    emit(HomeRefreshState(refreshTrigger: state.refreshTrigger + 1));
  }

  void onRefreshComplete() {
    emit(HomeRefreshState(refreshTrigger: state.refreshTrigger));
  }
}
