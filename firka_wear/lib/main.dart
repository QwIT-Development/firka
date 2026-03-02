import 'dart:io';

import 'package:firka_wear/app/app_state.dart';
import 'package:firka_wear/app/initialization_screen.dart';
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

  runApp(WearInitializationScreen());
}
