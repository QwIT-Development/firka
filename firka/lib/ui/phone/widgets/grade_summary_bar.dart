import 'package:firka/api/model/grade.dart';
import 'package:firka/ui/components/grade.dart';
import 'package:firka/ui/components/grade_helpers.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/l10n/app_localizations.dart';
import 'package:firka/ui/theme/style.dart';

class GradeSummaryBar extends StatefulWidget {
  final List<Grade> grades;
  final AppLocalizations l10n;

  const GradeSummaryBar({super.key, required this.grades, required this.l10n});

  @override
  State<GradeSummaryBar> createState() => _GradeSummaryBarState();
}

class _GradeSummaryBarState extends State<GradeSummaryBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final (total, countsByGrade) = getGradeDistribution(widget.grades);
    final gradeColors = [
      appStyle.colors.grade1,
      appStyle.colors.grade2,
      appStyle.colors.grade3,
      appStyle.colors.grade4,
      appStyle.colors.grade5,
    ];
    final totalCounted = countsByGrade.reduce((a, b) => a + b);

    return Card(
      shadowColor: Colors.transparent,
      color: appStyle.colors.a15p,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    widget.l10n.gradesCount(total),
                    style: appStyle.fonts.B_16SB.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: List.generate(5, (i) {
                          final flex = totalCounted > 0 ? countsByGrade[i] : 1;
                          return Expanded(
                            flex: flex,
                            child: Container(height: 10, color: gradeColors[i]),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final grade = i + 1;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: FittedBox(child: GradeIconWidget(grade)),
                        ),
                        const SizedBox(width: 4),
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
      ),
    );
  }
}
