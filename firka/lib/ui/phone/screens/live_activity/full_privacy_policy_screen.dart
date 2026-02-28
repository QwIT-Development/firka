import 'package:firka/app/app_state.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/core/state/firka_state.dart';

class FullPrivacyPolicyScreen extends StatefulWidget {
  final AppInitialization data;

  const FullPrivacyPolicyScreen({required this.data, super.key});

  @override
  State<FullPrivacyPolicyScreen> createState() =>
      _FullPrivacyPolicyScreenState();
}

class _FullPrivacyPolicyScreenState
    extends FirkaState<FullPrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: FirkaIconWidget(
                      FirkaIconType.majesticons,
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.data.l10n.la_privacy_header,
                      style: appStyle.fonts.H_H2.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.l10n.la_privacy_intro,
                        style: appStyle.fonts.B_16R.apply(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildPrivacySection(
                        widget.data.l10n.la_privacy_section1_title,
                        widget.data.l10n.la_privacy_section1_body,
                      ),
                      _buildPrivacySection(
                        widget.data.l10n.la_privacy_section2_title,
                        widget.data.l10n.la_privacy_section2_body,
                      ),
                      _buildPrivacySection(
                        widget.data.l10n.la_privacy_section3_title,
                        widget.data.l10n.la_privacy_section3_body,
                      ),
                      _buildPrivacySection(
                        widget.data.l10n.la_privacy_section4_title,
                        widget.data.l10n.la_privacy_section4_body,
                      ),
                      _buildPrivacySection(
                        widget.data.l10n.la_privacy_section5_title,
                        widget.data.l10n.la_privacy_section5_body,
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.data.l10n.la_privacy_footer,
                        style: appStyle.fonts.B_12R.apply(
                          color: appStyle.colors.textTertiary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.data.l10n.la_privacy_contact,
                        style: appStyle.fonts.B_12R.apply(
                          color: appStyle.colors.textTertiary,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: appStyle.fonts.H_16px.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            body,
            style: appStyle.fonts.B_16R.apply(
              color: appStyle.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
