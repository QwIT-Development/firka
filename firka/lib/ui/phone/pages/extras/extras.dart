import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/helpers/settings.dart';
import 'package:firka/helpers/ui/firka_shadow.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../helpers/firka_bundle.dart';
import '../../screens/debug/debug_screen.dart';
import '../../screens/home/home_screen.dart';

void showExtrasBottomSheet(BuildContext context, AppInitialization data) {
  Widget Function(double) debugBtn = (_) => const SizedBox();

  logger.finest("showExtrasBottomSheet() developer mode: ${isDeveloper()}");

  if (isDeveloper()) {
    debugBtn = (double itemWidth) => GestureDetector(
      // Fejlesztői menü
      onTap: () => {
        Navigator.pop(context),
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DefaultAssetBundle(
              bundle: FirkaBundle(),
              child: DebugScreen(data),
            ),
          ),
        ),
      },
      child: SizedBox(
        height: 60,
        width: itemWidth,
        child: FirkaShadow(
          shadow: true,
          child: Card(
            color: appStyle.colors.card,
            shadowColor: isLightMode.value ? null : Colors.transparent,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.bug2Solid,
                      size: 22.0,
                      color: appStyle.colors.accent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      data.l10n.debug_screen,
                      textAlign: TextAlign.right,
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  var debugCounter = 0;

  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.3,
    ),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            data.l10n.other,
                            style: appStyle.fonts.H_H2.apply(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 8) / 2;
                            return Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                debugBtn(itemWidth),
                                GestureDetector(
                                  // Fiókod
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DefaultAssetBundle(
                                              bundle: FirkaBundle(),
                                              child: SettingsScreen(
                                                data,
                                                data.settings.items.group(
                                                  "profile_settings",
                                                ),
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    height: 60,
                                    width: itemWidth,
                                    child: FirkaShadow(
                                      shadow: true,
                                      child: Card(
                                        color: appStyle.colors.card,
                                        shadowColor: isLightMode.value
                                            ? null
                                            : Colors.transparent,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                            ),
                                            child: Row(
                                              children: [
                                                FirkaIconWidget(
                                                  FirkaIconType.majesticons,
                                                  Majesticon.userSolid,
                                                  size: 22.0,
                                                  color: appStyle.colors.accent,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  data.l10n.s_your_account,
                                                  textAlign: TextAlign.right,
                                                  style: appStyle.fonts.B_16R
                                                      .apply(
                                                        color: appStyle
                                                            .colors
                                                            .textPrimary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  // Beállítás
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DefaultAssetBundle(
                                              bundle: FirkaBundle(),
                                              child: SettingsScreen(
                                                data,
                                                data.settings.items,
                                              ),
                                            ),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    height: 60,
                                    width: itemWidth,
                                    child: FirkaShadow(
                                      shadow: true,
                                      child: Card(
                                        color: appStyle.colors.card,
                                        shadowColor: isLightMode.value
                                            ? null
                                            : Colors.transparent,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                            ),
                                            child: Row(
                                              children: [
                                                FirkaIconWidget(
                                                  FirkaIconType.majesticons,
                                                  Majesticon.settingsCogSolid,
                                                  size: 22.0,
                                                  color: appStyle.colors.accent,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  data.l10n.settings_screen,
                                                  textAlign: TextAlign.right,
                                                  style: appStyle.fonts.B_16R
                                                      .apply(
                                                        color: appStyle
                                                            .colors
                                                            .textPrimary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Ide jön a többi gomb majd
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          GestureDetector(
                            child: Text(
                              "v${data.packageInfo.version} ${isBeta ? "beta" : ""}",
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textTertiary,
                              ),
                            ),
                            onTap: () async {
                              if (isDebug()) return;
                              if (debugCounter == 10) {
                                data.settings
                                    .group("settings")
                                    .setBoolean(
                                      "developer_enabled",
                                      !data.settings
                                          .group("settings")
                                          .boolean("developer_enabled"),
                                    );

                                await data.isar.writeTxn(() async {
                                  await data.settings
                                      .group("settings")["developer_enabled"]!
                                      .save(data.isar.appSettingsModels);
                                });

                                await data.settings
                                    .group("settings")["developer_enabled"]!
                                    .postUpdate();

                                Navigator.of(
                                  navigatorKey.currentContext!,
                                ).popUntil((route) => false);
                                Navigator.push(
                                  navigatorKey.currentContext!,
                                  MaterialPageRoute(
                                    builder: (context) => DefaultAssetBundle(
                                      bundle: FirkaBundle(),
                                      child: HomeScreen(
                                        data,
                                        false,
                                        key: ValueKey('homeScreen'),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (debugCounter < 10) {
                                debugCounter++;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
