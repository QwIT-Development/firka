import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:firka/app/initialization_screen.dart';

Future<void> ertesites(String title, String message) async {
  logger.info("REMOTE Title: $title");
  logger.info("REMOTE Message: $message");
  const NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'teszt',
      'Értesítés',
      channelDescription: 'Értesítés a Krétától.',
      importance: Importance.max,
      ticker: 'ticker',
    ),
  );
  await flnp.show(
    id: 0,
    title: title,
    body: message,
    notificationDetails: notificationDetails,
    payload: "szia",
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await ertesites(message.data["Title"], message.data["Message"]);
}

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

      await Firebase.initializeApp(
        name: defaultFirebaseAppName,
        options: FirebaseOptions(
          apiKey: "AIzaSyA_SnXigQkSvFuB5ECpgz8pZ1SjKzuKiFo",
          appId: "1:694136934013:android:2d6873f63e005250",
          androidClientId:
              "694136934013-6e2jmrbqume6lt92d2ceb5se6uru4uvm.apps.googleusercontent.com",
          projectId: "ellenorzo-v2",
          messagingSenderId: "694136934013",
          storageBucket: "ellenorzo-v2.appspot.com",
          databaseURL: "https://ellenorzo-v2.firebaseio.com",
        ),
      );

      FirebaseMessaging.instance.setAutoInitEnabled(true);

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      runApp(InitializationScreen());
    },
    (error, stackTrace) {
      logger.shout('Caught error: $error');
      logger.shout('Stack trace: $stackTrace');

      final message = '$error\n$stackTrace';
      appRouter?.go('/error', extra: message);
    },
  );
}
