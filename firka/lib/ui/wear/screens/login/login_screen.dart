// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:zear_plus/wear_plus.dart';

import '../../../../helpers/db/models/token_model.dart';
import '../../../../wear_main.dart';
import '../../../model/style.dart';
import '../home/home_screen.dart';

class WearLoginScreen extends StatefulWidget {
  final WearAppInitialization data;
  const WearLoginScreen(this.data, {super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreen(data);
}

class _WearLoginScreen extends State<WearLoginScreen> {
  final WearAppInitialization initData;
  _WearLoginScreen(this.initData);

  bool init = false;
  bool isPaired = false;
  bool isReachable = false;
  bool isMessageSending = false;
  bool isMessageSent = false;
  final watch = WatchConnectivity();
  late Timer connectionTimer;

  @override
  void initState() {
    super.initState();

    watch.messageStream.listen((e) {
      var msg = e.entries.toMap();
      var id = msg["id"];

      debugPrint("[Phone -> Watch]: $id");

      switch (id) {
        case "pong":
          {
            setState(() {
              isMessageSent = true;
            });
          }
        case "auth":
          {
            () async {
              var data = msg["data"];
              var tokenModel = TokenModel.fromValues(
                  data["studentId"],
                  data["iss"],
                  data["idToken"],
                  data["accessToken"],
                  data["refreshToken"],
                  data["expiryDate"]);

              initData.client = KretaClient(tokenModel, initData.isar);

              await initData.isar.writeTxn(() async {
                await initData.isar.tokenModels.put(tokenModel);
              });

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => WearHomeScreen(initData)),
                (route) => false, // Remove all previous routes
              );
            }();
          }
      }
    });

    connectionTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      var p = await watch.isPaired;
      var r = await watch.isReachable;

      if (!isMessageSending) {
        isMessageSending = true;

        debugPrint("[Watch -> Phone]: ping");
        watch.sendMessage({'id': 'ping'});
      }

      setState(() {
        init = true;
        isPaired = p;
        isReachable = r;
      });
    });
  }

  (List<Widget>, double) buildBody(BuildContext context) {
    if (!init) {
      return (
        <Widget>[
          Text(
            "Loading...",
            textAlign: TextAlign.center,
            style: wearStyle.fonts.H_18px
                .apply(color: wearStyle.colors.textPrimary),
          ),
        ],
        65
      );
    }

    if (!isPaired) {
      return (
        <Widget>[
          Text(
            "Watch not paired with your phone",
            textAlign: TextAlign.center,
            style: wearStyle.fonts.H_18px
                .apply(color: wearStyle.colors.textPrimary),
          ),
        ],
        65
      );
    }
    if (!isReachable) {
      return (
        <Widget>[
          Text(
            "Watch not connected\n to your phone",
            textAlign: TextAlign.center,
            style: wearStyle.fonts.H_18px
                .apply(color: wearStyle.colors.textPrimary),
          ),
        ],
        65
      );
    }

    if (!isMessageSent && isMessageSending) {
      return (
        <Widget>[
          Text(
            "Sending request...",
            textAlign: TextAlign.center,
            style: wearStyle.fonts.H_18px
                .apply(color: wearStyle.colors.textPrimary),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("[Watch -> Phone]: ping");
              watch.sendMessage({'id': 'ping'});
            },
            // TODO: This is a placeholder, style this properly
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return wearStyle.colors.accent;
                }
                return wearStyle.colors.accent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return wearStyle.colors.accent;
                }
                return wearStyle.colors.accent;
              }),
            ),
            child: Text('Try again',
                textAlign: TextAlign.center,
                style: TextStyle(color: wearStyle.colors.textPrimary)),
          ),
        ],
        45
      );
    }

    if (isMessageSent) {
      return (
        <Widget>[
          Text(
            "Check your phone!",
            textAlign: TextAlign.center,
            style: wearStyle.fonts.H_18px
                .apply(color: wearStyle.colors.textPrimary),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("[Watch -> Phone]: ping");
              watch.sendMessage({'id': 'ping'});
            },
            // TODO: This is a placeholder, style this properly
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return wearStyle.colors.accent;
                }
                return wearStyle.colors.accent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return wearStyle.colors.accent;
                }
                return wearStyle.colors.accent;
              }),
            ),
            child: Text('Try again',
                textAlign: TextAlign.center,
                style: TextStyle(color: wearStyle.colors.textPrimary)),
          ),
        ],
        45
      );
    }

    return (
      <Widget>[
        Text("Unexpected state",
            style: TextStyle(color: wearStyle.colors.textPrimary, fontSize: 18),
            textAlign: TextAlign.center),
      ],
      65
    );
  }

  @override
  Widget build(BuildContext context) {
    var (body, offset) = buildBody(context);

    return Scaffold(
      backgroundColor: wearStyle.colors.background,
      body: Center(
        child: Column(
          children: [
            WatchShape(
                builder: (context, shape, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Login",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: wearStyle.colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(top: offset),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: body,
                              )),
                        ],
                      ),
                      child!,
                    ],
                  );
                },
                child: SizedBox())
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    connectionTimer.cancel();
  }
}
