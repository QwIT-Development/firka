import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/app/initialization_screen.dart';
import 'package:firka/ui/phone/pages/error/error_page.dart';

void main() async {
  logger = Logger("Firka");
  dio.options.connectTimeout = Duration(seconds: 5);
  dio.options.receiveTimeout = Duration(seconds: 3);
  dio.options.validateStatus = (status) => status != null && status < 500;

  runZonedGuarded(
    () async {
      logger.finest("Initializing app");
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      try {
        await dotenv.load(fileName: ".env");
        logger.info("Environment variables loaded");
      } catch (e, st) {
        logger.severe("Failed to load .env: $e", e, st);
      }

      await setupLogging();

      runApp(InitializationScreen());
    },
    (error, stackTrace) {
      logger.shout('Caught error: $error');
      logger.shout('Stack trace: $stackTrace');

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ErrorPage(
            key: ValueKey('errorPage'),
            exception: error.toString(),
          ),
        ),
      );
    },
  );
}
