import 'dart:typed_data';

import 'package:firka/helpers/ui/firka_button.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/live_activity/full_privacy_policy_screen.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../helpers/firka_state.dart';

class LiveActivityConsentScreen extends StatefulWidget {
  final AppInitialization data;

  const LiveActivityConsentScreen({
    required this.data,
    super.key,
  });

  @override
  State<LiveActivityConsentScreen> createState() =>
      _LiveActivityConsentScreenState();
}

class _LiveActivityConsentScreenState
    extends FirkaState<LiveActivityConsentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.bellSolid,
                    color: appStyle.colors.accent,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.data.l10n.la_title,
                      style: appStyle.fonts.H_H1
                          .apply(color: appStyle.colors.textPrimary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  widget.data.l10n.la_subtitle,
                  style: appStyle.fonts.B_16R
                      .apply(color: appStyle.colors.textSecondary),
                  maxLines: null,
                  softWrap: true,
                ),
              ),
              SizedBox(height: 24),

              Card(
                color: appStyle.colors.warningCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.shieldSolid,
                            color: appStyle.colors.warningAccent,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.data.l10n.la_privacy_title,
                              style: appStyle.fonts.H_16px
                                  .apply(color: appStyle.colors.warningText),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.data.l10n.la_privacy_required,
                        style: appStyle.fonts.B_14R
                            .apply(color: appStyle.colors.warningText),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.l10n.la_privacy_intro,
                        style: appStyle.fonts.B_16R
                            .apply(color: appStyle.colors.textPrimary),
                      ),
                      SizedBox(height: 16),
                      _buildPrivacySummaryItem(
                        icon: Majesticon.editPen4Solid,
                        title: widget.data.l10n.la_privacy_section1_title,
                        description: widget.data.l10n.la_privacy_summary1,
                      ),
                      _buildPrivacySummaryItem(
                        icon: Majesticon.lockSolid,
                        title: widget.data.l10n.la_privacy_section2_title,
                        description: widget.data.l10n.la_privacy_summary2,
                      ),
                      _buildPrivacySummaryItem(
                        icon: Majesticon.clockSolid,
                        title: widget.data.l10n.la_privacy_section3_title,
                        description: widget.data.l10n.la_privacy_summary3,
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      FullPrivacyPolicyScreen(data: widget.data)));
                        },
                        child: FirkaCard(
                          left: [
                            Text(
                              widget.data.l10n.la_learn_more,
                              style: appStyle.fonts.B_16SB
                                  .apply(color: appStyle.colors.accent),
                            ),
                          ],
                          right: [
                            FirkaIconWidget(
                              FirkaIconType.majesticons,
                              Majesticon.chevronRightLine,
                              color: appStyle.colors.accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, false);
                      },
                      child: FirkaButton(
                        text: widget.data.l10n.la_decline,
                        bgColor: appStyle.colors.buttonSecondaryFill,
                        fontStyle: appStyle.fonts.B_16R
                            .apply(color: appStyle.colors.textSecondary),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, true);
                      },
                      child: FirkaButton(
                        text: widget.data.l10n.la_accept,
                        bgColor: appStyle.colors.accent,
                        fontStyle: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textSecondaryLight),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySummaryItem({
    required Uint8List icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FirkaIconWidget(
            FirkaIconType.majesticons,
            icon,
            color: appStyle.colors.accent,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: appStyle.fonts.B_14SB
                      .apply(color: appStyle.colors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: appStyle.fonts.B_14R
                      .apply(color: appStyle.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
