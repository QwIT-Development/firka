import "package:dart_jsonwebtoken/dart_jsonwebtoken.dart";
import "package:firka/app/app_state.dart";
import "package:firka/app/initialization.dart";
import "package:firka/services/fcm_service.dart";
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

    await FcmService.onUserLogout();

    await data.settings.setSelectedAccountKey(token.key);
    await initializeApp();

    if (data.client != null) {
      await FcmService.onUserLogin(
        client: data.client!,
        settingsStore: data.settings,
      );
    }

    if (!context.mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
    appRouter?.go('/home');
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FcmService.onUserLogout();

      final active = data.client!.cache.token.key;

      try {
        await data.client!.cache.clearAccountData();
      } catch (e) {
        logger.warning('[Settings] Failed to clear cached data on logout: $e');
      }

      await data.isar.writeTxn(() async {
        await data.isar.tokenModels.delete(active);
      });
      await data.settings.setSelectedAccountKey(0);

      final accounts = await data.isar.tokenModels.where().findAll();

      await initializeApp();

      if (context.mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      }
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
