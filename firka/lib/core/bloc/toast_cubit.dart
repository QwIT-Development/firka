import 'package:firka/ui/phone/pages/extras/firka_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ActiveToastType { fetching, error, reauth, none }

class ToastState {
  final ActiveToastType type;
  final Object? extra;

  const ToastState(this.type, [this.extra]);

  Widget? buildWidget(BuildContext context) {
    switch (type) {
      case .fetching:
        return FirkaToastWidget.fetching(context);
      case .error:
        return FirkaToastWidget.error(context, extra!);
      case .reauth:
        return FirkaToastWidget.reauth(context);
      case .none:
        return null;
    }
  }
}

class ToastCubit extends Cubit<ToastState> {
  ToastCubit() : super(const ToastState(ActiveToastType.none));

  void setActiveToast(ActiveToastType type, [Object? extra]) {
    emit(ToastState(type, extra));
  }

  void clear() {
    setActiveToast(ActiveToastType.none);
  }
}
