import 'dart:io';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/settings/setting.dart';
import 'package:firka/helpers/ui/firka_button.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:flutter/material.dart';

import '../../../../main.dart';

class BetaScreen extends StatelessWidget {
  final AppInitialization data;

  const BetaScreen(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
          child: Column(
        children: [
          Spacer(),
          Center(
            child: Text(data.l10n.beta_title,
                style: appStyle.fonts.H_H1
                    .apply(color: appStyle.colors.textPrimary)),
          ),
          SizedBox(height: 32),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                data.l10n.beta_body,
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
                      text: data.l10n.cancel,
                      bgColor: appStyle.colors.buttonSecondaryFill,
                      fontStyle: appStyle.fonts.B_14R
                          .apply(color: appStyle.colors.textPrimary),
                      icon: Icon(Icons.close, color: appStyle.colors.textPrimary),
                    ),
                    onTap: () {
                      exit(0);
                    },
                  ),
                  GestureDetector(
                    child: FirkaButton(
                      text: data.l10n.okay,
                      bgColor: appStyle.colors.accent,
                      fontStyle: appStyle.fonts.B_14R
                          .apply(color: appStyle.colors.textPrimary),
                      icon: Icon(Icons.check, color: appStyle.colors.textPrimary),
                    ),
                    onTap: () async {
                      await data.isar.writeTxn(() async {
                        data.settings
                            .group("settings")
                            .setBoolean("beta_warning", true);

                        await data.settings
                            .group("settings")["beta_warning"]!
                            .save(data.isar.appSettingsModels);

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => HomeScreen(data, false)),
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
}
