import 'package:firka/core/settings.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/widgets/login_webview.dart';
import 'package:flutter/material.dart';

void showReauthBottomSheet(
  BuildContext context,
  AppInitialization data,
  String message,
) {
  final accountPicker =
      (data.settings.group("profile_settings")["e_kreta_account_picker"]
          as SettingsKretenAccountPicker);

  final currentToken =
      data.tokens.isNotEmpty && accountPicker.accountIndex < data.tokens.length
      ? data.tokens[accountPicker.accountIndex]
      : null;

  final username = currentToken?.studentId;
  final schoolId = currentToken?.iss;

  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: appStyle.colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: appStyle.colors.errorCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text(
                message,
                style: appStyle.fonts.B_16R.copyWith(
                  color: appStyle.colors.errorText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: LoginWebviewWidget(
                data,
                username: username,
                schoolId: schoolId,
              ),
            ),
          ],
        ),
      );
    },
  );
}
