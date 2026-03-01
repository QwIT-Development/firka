import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firka_wear/app/initialization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

final dio = Dio();

void main() async {
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
