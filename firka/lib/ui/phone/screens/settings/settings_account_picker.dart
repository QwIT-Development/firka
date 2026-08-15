import "dart:io";

import "package:dart_jsonwebtoken/dart_jsonwebtoken.dart";
import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/services/live_activity_service.dart";
import "package:firka/services/watch_sync_helper.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka/ui/phone/widgets/login_webview.dart";
import "package:firka_common/data/models/token_model.dart";
import "package:firka_common/ui/components/firka_card.dart";
import "package:flutter/material.dart";
import "package:isar_community/isar.dart";

class SettingsAccountPickerView extends StatelessWidget {
  final AppInitialization data;
  final List<TokenModel> tokens;
  final void Function(VoidCallback fn) setStateOuter;

  const SettingsAccountPickerView({
    required this.data,
    required this.tokens,
    required this.setStateOuter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final token in tokens) ...[
          _accountRow(context, token),
          SizedBox(height: 8),
        ],
        GestureDetector(
          child: FirkaCard(
            left: [
              Text(
                data.l10n.s_acc_add,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ],
          ),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              builder: (BuildContext context) {
                return LoginWebviewWidget(data);
              },
            );
          },
        ),
        SizedBox(height: 20),
        GestureDetector(
          child: FirkaCard(
            left: [
              Row(
                children: [
                  FirkaIconWidget(
                    FirkaIconType.icons,
                    "group",
                    color: appStyle.colors.accent,
                  ),
                  SizedBox(width: 8),
                  Text(
                    data.l10n.s_acc_logout,
                    style: appStyle.fonts.B_16R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Widget _accountRow(BuildContext context, TokenModel token) {
    final jwt = JWT.decode(token.idToken);
    final payload = jwt.payload as Map<String, dynamic>;
    String studentRole = payload["role"];
    if (studentRole == "Tanulo") {
      studentRole = "Tanuló";
    } else if (studentRole == "Gondviselo") {
      studentRole = "Gondviselő";
    }

    return GestureDetector(
      child: SizedBox(
        height: 52,
        child: FirkaCard(
          left: [
            Text(
              payload["name"],
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              studentRole,
              style: appStyle.fonts.B_16R.apply(
                color: appStyle.colors.textTertiary,
              ),
            ),
          ],
          right: [
            token.key != data.settings.selectedAccountKey
                ? SizedBox()
                : Checkbox(
                    value: true,
                    fillColor: WidgetStateProperty.resolveWith<Color>((
                      Set<WidgetState> states,
                    ) {
                      return appStyle.colors.secondary;
                    }),
                    onChanged: (_) async {
                      setStateOuter(() {});
                      logger.finest('Settings saved');
                    },
                  ),
          ],
        ),
      ),
      onTap: () => _switchAccount(context, token),
    );
  }

  Future<void> _switchAccount(BuildContext context, TokenModel token) async {
    if (token.key == data.settings.selectedAccountKey) {
      return;
    }

    final previousAccountId = data.client!.cache.token.key;
    if (Platform.isIOS) {
      await LiveActivityService.onUserLogout();
      try {
        await WatchSyncHelper.clearSharedLanguageState();
      } catch (e) {
        logger.warning(
          '[Settings] Failed to clear shared language state on account switch: $e',
        );
      }
      try {
        await WatchSyncHelper.clearRefreshLeaseForAccount(previousAccountId);
      } catch (e) {
        logger.warning(
          '[Settings] Failed to clear refresh lease on account switch: $e',
        );
      }
    }

    await data.settings.setSelectedAccountKey(token.key);
    await initializeApp();

    if (Platform.isIOS) {
      var watchReachable = false;
      try {
        watchReachable = await WatchSyncHelper.isWatchReachable(
          forceRefreshInstall: true,
        );
      } catch (e) {
        logger.warning(
          '[Settings] Failed to query Watch reachability on account switch: $e',
        );
      }

      if (watchReachable) {
        try {
          await WatchSyncHelper.sendTokenModelToWatch(
            token,
            allowExpiredAccessToken: true,
          );
        } catch (e) {
          logger.warning(
            '[Settings] Failed to send switched account token to reachable Watch: $e',
          );
        }
      } else {
        try {
          await WatchSyncHelper.saveTokenToiCloud(
            token,
            forceAccountSwitch: true,
          );
        } catch (e) {
          logger.warning(
            '[Settings] Failed to sync switched account token to iCloud: $e',
          );
        }
      }
    }

    if (!context.mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
    appRouter?.go('/home');
  }

  Future<void> _logout(BuildContext context) async {
    try {
      if (Platform.isIOS) {
        await LiveActivityService.onUserLogout();
      }

      final active = data.client!.cache.token.key;
      if (Platform.isIOS) {
        try {
          await WatchSyncHelper.clearRefreshLeaseForAccount(active);
        } catch (e) {
          logger.warning(
            '[Settings] Failed to clear refresh lease for active account: $e',
          );
        }
        try {
          await WatchSyncHelper.clearSharedLanguageState();
        } catch (e) {
          logger.warning(
            '[Settings] Failed to clear shared language state on logout: $e',
          );
        }
      }

      await data.isar.writeTxn(() async {
        await data.isar.tokenModels.delete(active);
      });
      await data.settings.setSelectedAccountKey(0);

      final accounts = await data.isar.tokenModels.where().findAll();

      if (accounts.isEmpty) {
        if (Platform.isIOS) {
          try {
            await WatchSyncHelper.clearICloudToken(notifyWatch: true);
            await WatchSyncHelper.clearAllRefreshLeases();
          } catch (e) {
            logger.warning('[Settings] Failed to clear iCloud token: $e');
          }
        }
      } else {
        if (Platform.isIOS) {
          final nextToken = accounts.first;
          var watchReachable = false;
          try {
            watchReachable = await WatchSyncHelper.isWatchReachable(
              forceRefreshInstall: true,
            );
          } catch (e) {
            logger.warning(
              '[Settings] Failed to query Watch reachability after logout: $e',
            );
          }

          if (watchReachable) {
            try {
              await WatchSyncHelper.sendTokenModelToWatch(
                nextToken,
                allowExpiredAccessToken: true,
              );
            } catch (e) {
              logger.warning(
                '[Settings] Failed to send next account token to reachable Watch after logout: $e',
              );
            }
          } else {
            try {
              await WatchSyncHelper.saveTokenToiCloud(
                nextToken,
                forceAccountSwitch: true,
              );
            } catch (e) {
              logger.warning(
                '[Settings] Failed to sync next account token to iCloud after logout: $e',
              );
            }
          }
        }
      }

      await initializeApp();

      if (!context.mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
      if (accounts.isEmpty) {
        appRouter?.go('/login');
      } else {
        appRouter?.go('/home');
      }
    } catch (e, st) {
      logger.shout('[Settings] Logout failed: $e', e, st);
      if (context.mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      }
      appRouter?.go('/login');
    }
  }
}
