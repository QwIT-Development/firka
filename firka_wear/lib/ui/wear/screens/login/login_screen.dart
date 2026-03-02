// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:wear_plus/wear_plus.dart';

import 'package:firka_wear/app/initialization.dart';
import 'package:firka_wear/data/models/token_model.dart';
import 'package:firka_wear/ui/theme/style.dart';
import 'package:firka_wear/ui/wear/screens/home/home_screen.dart';

class WearLoginScreen extends StatefulWidget {
  final WearAppInitialization data;
  const WearLoginScreen(this.data, {super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreen();
}

class _WearLoginScreen extends State<WearLoginScreen> {
  WearAppInitialization get initData => widget.data;

  bool init = false;
  bool isPaired = false;
  bool isReachable = false;
  bool isMessageSending = false;
  bool isMessageSent = false;
  bool isSyncing = false;
  final watch = WatchConnectivity();
  late Timer connectionTimer;

  @override
  void initState() {
    super.initState();

    watch.messageStream.listen((e) {
      final raw = Map<String, dynamic>.from(e);
      final data = raw['data'];
      final msg = data is String
          ? jsonDecode(data) as Map<String, dynamic>
          : raw;
      var id = msg["id"];

      debugPrint("[Phone -> Watch]: $id");

      switch (id) {
        case "init_data":
          () async {
            if (!mounted) return;
            setState(() => isSyncing = true);
            try {
              final auth = msg["auth"] as Map<dynamic, dynamic>?;
              if (auth == null) return;
              final tokenModel = TokenModel.fromValues(
                auth["studentIdNorm"] as int,
                auth["studentId"] as String,
                auth["iss"] as String,
                auth["idToken"] as String,
                auth["accessToken"] as String,
                auth["refreshToken"] as String,
                auth["expiryDate"] as int,
              );
              await initData.isar.writeTxn(() async {
                await initData.isar.tokenModels.put(tokenModel);
              });
              final lastSyncAt = msg["lastSyncAt"] != null
                  ? DateTime.parse(msg["lastSyncAt"] as String)
                  : null;
              final rawTimetable = msg["timetable"] as List<dynamic>? ?? [];
              final timetable = rawTimetable
                  .map(
                    (e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList();
              final rawGrades = msg["grades"] as List<dynamic>? ?? [];
              final grades = rawGrades
                  .map(
                    (e) => Grade.fromJson(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList();
              await initData.syncStore.save(
                lastSyncAt: lastSyncAt,
                timetable: timetable,
                grades: grades,
              );
              watch.sendMessage(<String, dynamic>{
                'data': jsonEncode(<String, dynamic>{'id': 'init_done'}),
              });
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => WearHomeScreen(initData),
                ),
                (route) => false,
              );
            } finally {
              if (mounted) setState(() => isSyncing = false);
            }
          }();
          break;
      }
    });

    connectionTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      var p = await watch.isPaired;
      var r = await watch.isReachable;

      if (!isMessageSending) {
        isMessageSending = true;

        debugPrint("[Watch -> Phone]: ping");
        watch.sendMessage(<String, dynamic>{
          'data': jsonEncode(<String, dynamic>{'id': 'ping'}),
        });
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
      return (<Widget>[], 60);
    }

    if (isSyncing) {
      return (
        <Widget>[
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            widget.data.l10n.wear_syncing,
            textAlign: TextAlign.center,
            style: wearStyle.fonts.B_16R.apply(
              color: wearStyle.colors.textPrimary,
            ),
          ),
        ],
        60,
      );
    }

    if (!isPaired) {
      return (
        <Widget>[
          Text(
            widget.data.l10n.wear_phone_unpaired,
            textAlign: TextAlign.center,
            style: wearStyle.fonts.B_14R.apply(
              color: wearStyle.colors.textPrimary,
            ),
          ),
        ],
        60,
      );
    }
    if (!isReachable) {
      return (
        <Widget>[
          Text(
            widget.data.l10n.wear_phone_disconnected,
            textAlign: TextAlign.center,
            style: wearStyle.fonts.B_16R.apply(
              color: wearStyle.colors.textPrimary,
            ),
          ),
        ],
        60,
      );
    }

    if (!isMessageSent && isMessageSending) {
      return (
        <Widget>[
          Text(
            widget.data.l10n.wear_pairing_request_sent,
            textAlign: TextAlign.center,
            style: wearStyle.fonts.B_16R.apply(
              color: wearStyle.colors.textPrimary,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("[Watch -> Phone]: ping");
              watch.sendMessage(<String, dynamic>{
                'data': jsonEncode(<String, dynamic>{
                  'id': 'ping',
                  'model': initData.devInfo.model,
                }),
              });
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
            child: Text(
              widget.data.l10n.wear_try_again,
              textAlign: TextAlign.center,
              style: TextStyle(color: wearStyle.colors.textPrimary),
            ),
          ),
        ],
        45,
      );
    }

    if (isMessageSent) {
      return (
        <Widget>[
          Text(
            widget.data.l10n.wear_pairing_check_phone,
            textAlign: TextAlign.center,
            style: wearStyle.fonts.B_16R.apply(
              color: wearStyle.colors.textPrimary,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint("[Watch -> Phone]: ping");
              watch.sendMessage(<String, dynamic>{
                'data': jsonEncode(<String, dynamic>{'id': 'ping'}),
              });
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
            child: Text(
              widget.data.l10n.wear_try_again,
              textAlign: TextAlign.center,
              style: TextStyle(color: wearStyle.colors.textPrimary),
            ),
          ),
        ],
        55,
      );
    }

    return (
      <Widget>[
        Text(
          "Unexpected state",
          style: TextStyle(color: wearStyle.colors.textPrimary, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
      60,
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
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(top: offset),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: body,
                          ),
                        ),
                      ],
                    ),
                    child!,
                  ],
                );
              },
              child: SizedBox(),
            ),
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
