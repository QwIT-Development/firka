import 'dart:async';
import 'dart:io';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/helpers/ui/firka_button.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/firka_state.dart';
import '../../../../main.dart';

class BetaScreen extends StatefulWidget {
  final AppInitialization data;

  const BetaScreen(this.data, {super.key});

  @override
  State<BetaScreen> createState() => _BetaScreenState();
}

class _BetaScreenState extends FirkaState<BetaScreen> {
  late Timer timer;
  int counter = 5;

  @override
  void initState() {
    super.initState();

    counter = 5;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (counter == 0) {
        timer.cancel();
      } else {
        counter--;

        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
          child: Column(
        children: [
          Spacer(),
          Center(
            child: Text(widget.data.l10n.beta_title,
                style: appStyle.fonts.H_H1
                    .apply(color: appStyle.colors.textPrimary)),
          ),
          SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.data.l10n.beta_body,
                style: appStyle.fonts.B_16R
                    .apply(color: appStyle.colors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Spacer(),
          Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: FirkaButton(
                      text: widget.data.l10n.cancel,
                      bgColor: appStyle.colors.buttonSecondaryFill,
                      fontStyle: appStyle.fonts.B_14R
                          .apply(color: appStyle.colors.textPrimaryLight),
                      icon: Icon(Icons.close,
                          color: appStyle.colors.textPrimaryLight),
                    ),
                    onTap: () {
                      exit(0);
                    },
                  ),
                  GestureDetector(
                    child: FirkaButton(
                      text: counter == 0
                          ? widget.data.l10n.okay
                          : "${widget.data.l10n.okay} ($counter)",
                      bgColor: counter == 0
                          ? appStyle.colors.accent
                          : appStyle.colors.secondary,
                      fontStyle: appStyle.fonts.B_14R
                          .apply(color: appStyle.colors.textPrimaryLight),
                      icon: Icon(Icons.check,
                          color: appStyle.colors.textPrimaryLight),
                    ),
                    onTap: () async {
                      if (counter != 0) return;
                      await widget.data.isar.writeTxn(() async {
                        widget.data.settings
                            .group("settings")
                            .setBoolean("beta_warning", true);

                        await widget.data.settings
                            .group("settings")["beta_warning"]!
                            .save(widget.data.isar.appSettingsModels);

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) =>
                                  HomeScreen(widget.data, false)),
                          (route) => false,
                        );
                      });
                    },
                  ),
                ],
              )),
        ],
      )),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
