import 'package:firka_common/ui/components/firka_card.dart';
import 'package:firka_common/core/grade_helper.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/ui/components/grade.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/theme/style.dart';

class GradeSummaryBar extends StatefulWidget {
  final List<GradeCacheModel> grades;
  final AppLocalizations l10n;
  final bool showAverage;

  const GradeSummaryBar({
    super.key,
    required this.grades,
    required this.l10n,
    this.showAverage = false,
  });

  @override
  State<GradeSummaryBar> createState() => _GradeSummaryBarState();
}

class _GradeSummaryBarState extends State<GradeSummaryBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final (total, countsByGrade) = widget.grades.getGradeDistribution();
    final averageText = widget.showAverage
        ? (widget.grades.getAverage() ?? 0).toStringAsFixed(2)
        : '';
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: List.generate(5, (i) {
          final flex = total > 0 ? countsByGrade[i] : 1;
          return Expanded(
            flex: flex,
            child: Container(height: 12, color: getGradeColor(i + 1)),
          );
        }),
      ),
    );

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: FirkaCard.single(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(horizontal: 16),
        height: _expanded ? 115 : 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                Text(
                  widget.showAverage
                      ? '${widget.l10n.gradesCount(total)} ($averageText)'
                      : widget.l10n.gradesCount(total),
                  style: appStyle.fonts.B_16SB.apply(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
                Expanded(child: _expanded ? SizedBox() : bar),
                FirkaIconWidget(
                  FirkaIconType.majesticons,
                  _expanded
                      ? Majesticon.chevronUpLine
                      : Majesticon.chevronDownLine,
                  color: appStyle.colors.textPrimary,
                  size: 24,
                ),
              ],
            ),
            if (_expanded) ...[
              bar,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final grade = i + 1;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      GradeWidget.gradeValue(grade, size: 27),
                      Text(
                        countsByGrade[i].toString(),
                        style: appStyle.fonts.B_16SB.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
