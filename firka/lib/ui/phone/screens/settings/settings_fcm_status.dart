import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

import "package:firka/app/app_state.dart";
import "package:firka/core/last_seen_helper.dart";
import "package:firka/services/fcm_service.dart";
import "package:firka/services/notification_diff_service.dart";
import "package:firka/ui/phone/screens/settings/settings_metrics.dart";
import "package:firka/ui/shared/firka_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/ui/components/firka_card.dart";

/// Read-only diagnostic panel for the developer settings screen: shows
/// whether FcmService has initialized, whether a token/permission is
/// present, which wakeup topic is currently subscribed, and when the token
/// last refreshed. Has its own refresh button since permission status is
/// read asynchronously and can change outside the app (system settings).
class SettingsFcmStatusView extends StatefulWidget {
  final AppInitialization data;

  const SettingsFcmStatusView({required this.data, super.key});

  @override
  State<SettingsFcmStatusView> createState() => _SettingsFcmStatusViewState();
}

class _SettingsFcmStatusViewState extends State<SettingsFcmStatusView> {
  AuthorizationStatus? _permissionStatus;
  bool _permissionLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    final status = await FcmService.permissionStatus();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _permissionLoaded = true;
    });
  }

  String _permissionLabel() {
    final l10n = widget.data.l10n;
    if (!_permissionLoaded) return "…";
    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return l10n.s_fcm_status_permission_granted;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.deniedPermanently:
        return l10n.s_fcm_status_permission_denied;
      case AuthorizationStatus.notDetermined:
      case null:
        return l10n.s_fcm_status_permission_unknown;
    }
  }

  List<(String kind, String label)> _testKinds() {
    final l10n = widget.data.l10n;
    return [
      (LastSeenHelper.notifGrades, l10n.s_notif_grades),
      (LastSeenHelper.notifHomework, l10n.s_notif_homework_tests),
      (LastSeenHelper.notifTests, l10n.s_notif_homework_tests),
      (LastSeenHelper.notifAbsences, l10n.s_notif_absences),
      (LastSeenHelper.notifLessons, l10n.s_notif_lessons),
      (LastSeenHelper.notifLessonsCancelled, l10n.s_notif_lessons_cancelled),
      (LastSeenHelper.notifLessonsSubstituted, l10n.s_notif_lessons_substituted),
      (LastSeenHelper.notifMessages, l10n.s_notif_messages),
    ];
  }

  Widget _testButton(String kind, String label, {bool simulateMultiAccount = false}) {
    final scale = settingsScale(context);

    return GestureDetector(
      onTap: () => NotificationDiffService.showTestNotification(
        kind,
        simulateMultiAccount: simulateMultiAccount,
      ),
      child: FirkaCard(
        height: settingsItemHeight * scale,
        rounding: settingsItemRounding * scale,
        left: [
          FirkaIconWidget(
            FirkaIconType.majesticons,
            Majesticon.bellSolid,
            color: appStyle.colors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: appStyle.fonts.B_16SB.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final scale = settingsScale(context);

    return FirkaCard(
      height: settingsItemHeight * scale,
      rounding: settingsItemRounding * scale,
      left: [
        Text(
          label,
          style: appStyle.fonts.B_16R.apply(color: appStyle.colors.textPrimary),
        ),
      ],
      right: [
        Text(
          value,
          style: appStyle.fonts.B_16R.apply(
            color: appStyle.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.data.l10n;
    final scale = settingsScale(context);
    final initialized = FcmService.isInitialized;
    final token = FcmService.cachedToken;
    final lastRefresh = FcmService.lastTokenRefreshAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          l10n.s_fcm_status_title,
          initialized
              ? l10n.s_fcm_status_initialized
              : l10n.s_fcm_status_not_initialized,
        ),
        _row(
          token != null
              ? l10n.s_fcm_status_token_present
              : l10n.s_fcm_status_token_missing,
          token != null ? "...${token.substring(token.length - 6)}" : "-",
        ),
        _row(l10n.s_fcm_status_permission_label, _permissionLabel()),
        _row(l10n.s_fcm_status_topic_label, FcmService.subscribedTopic),
        _row(
          l10n.s_fcm_status_last_refresh_label,
          lastRefresh?.toIso8601String() ?? l10n.s_fcm_status_last_refresh_never,
        ),
        GestureDetector(
          onTap: _loadPermissionStatus,
          child: FirkaCard(
            height: settingsItemHeight * scale,
            rounding: settingsItemRounding * scale,
            left: [
              FirkaIconWidget(
                FirkaIconType.majesticons,
                Majesticon.reloadSolid,
                color: appStyle.colors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.s_fcm_status_refresh_button,
                style: appStyle.fonts.B_16SB.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.s_fcm_test_notifications_title,
          style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
        ),
        for (final (kind, label) in _testKinds()) _testButton(kind, label),
        const SizedBox(height: 12),
        Text(
          l10n.s_fcm_test_notifications_multi_title,
          style: appStyle.fonts.B_16SB.apply(color: appStyle.colors.textPrimary),
        ),
        for (final (kind, label) in _testKinds())
          _testButton(kind, label, simulateMultiAccount: true),
      ],
    );
  }
}
