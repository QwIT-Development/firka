import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/core/settings/settings_repository.dart';
import 'package:firka/core/settings/settings_schema.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:firka/ui/theme/style.dart';

Widget _extrasActionTile({
  required double width,
  required VoidCallback onTap,
  required Widget icon,
  required String label,
}) {
  return GestureDetector(
    onTap: onTap,
    child: FirkaCard.single(
      width: width,
      height: 60,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showExtrasBottomSheet(BuildContext context, AppInitialization data) {
  Widget Function(double) debugBtn = (_) => const SizedBox();

  logger.finest("showExtrasBottomSheet() developer mode: ${isDeveloper()}");

  if (isDeveloper()) {
    debugBtn = (double itemWidth) => _extrasActionTile(
      // Fejlesztői menü
      width: itemWidth,
      onTap: () {
        context.pop();
        context.push('/debug');
      },
      icon: FirkaIconWidget(
        FirkaIconType.majesticons,
        Majesticon.bug2Solid,
        size: 22.0,
        color: appStyle.colors.accent,
      ),
      label: data.l10n.debug_screen,
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
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                debugBtn(itemWidth),
                                _extrasActionTile(
                                  // Fiókod
                                  width: itemWidth,
                                  onTap: () {
                                    context.pop();
                                    context.push(
                                      '/settings',
                                      extra: buildProfileSettingsTree(
                                        data.l10n,
                                      ).children,
                                    );
                                  },
                                  icon: FirkaIconWidget(
                                    FirkaIconType.majesticons,
                                    Majesticon.userSolid,
                                    size: 22.0,
                                    color: appStyle.colors.accent,
                                  ),
                                  label: data.l10n.s_your_account,
                                ),
                                _extrasActionTile(
                                  // Beállítás
                                  width: itemWidth,
                                  onTap: () {
                                    context.pop();
                                    context.push('/settings');
                                  },
                                  icon: FirkaIconWidget(
                                    FirkaIconType.majesticons,
                                    Majesticon.settingsCogSolid,
                                    size: 22.0,
                                    color: appStyle.colors.accent,
                                  ),
                                  label: data.l10n.settings_screen,
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
                                final navigator = Navigator.of(context);
                                final router = GoRouter.of(context);
                                await Settings.developerOptsEnabled.set(
                                  !Settings.developerOptsEnabled.value,
                                );

                                navigator.pop();
                                router.go('/home');
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
