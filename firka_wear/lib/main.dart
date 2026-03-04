import 'dart:async';
import 'dart:io';

import 'package:firka_wear/app/app_state.dart';
import 'package:firka_wear/app/initialization_screen.dart';
import 'package:firka_wear/ui/wear/screens/error/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  logger = Logger('FirkaWear');

  dio.options.connectTimeout = Duration(seconds: 5);
  dio.options.receiveTimeout = Duration(seconds: 3);
  dio.options.validateStatus = (status) => status != null && status < 500;

  WidgetsFlutterBinding.ensureInitialized();

  if (await Permission.notification.isDenied) {
    var status = await Permission.notification.request();

    if (status.isDenied) {
      exit(-1);
    }
  }

  await ScreenUtil.ensureScreenSize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (_isFatalError(details.exception)) {
      globalErrorNotifier.value = details;
    }
  };

  runZonedGuarded(() => runApp(const _WearAppWrapper()), (
    Object error,
    StackTrace stackTrace,
  ) {
    if (_isFatalError(error)) {
      globalErrorNotifier.value = FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'firka_wear',
      );
    }
  });
}

bool _isFatalError(Object error) {
  return error is! AssertionError;
}

class _WearAppWrapper extends StatelessWidget {
  const _WearAppWrapper();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FlutterErrorDetails?>(
      valueListenable: globalErrorNotifier,
      builder: (context, error, _) {
        if (error != null) {
          return MaterialApp(
            home: WearErrorScreen(
              exception: error.exception,
              stackTrace: error.stack,
            ),
          );
        }
        return WearInitializationScreen();
      },
    );
  }
}
