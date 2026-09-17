import 'package:flutter/material.dart';
import 'package:firka/ui/theme/style.dart';

class StatsForNerdsTable extends StatelessWidget {
  final List<(String, String)> rows;

  const StatsForNerdsTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 0.5,
              color: appStyle.colors.shadowColor,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    rows[i].$1,
                    style: appStyle.fonts.B_12R.apply(
                      color: appStyle.colors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: appStyle.fonts.B_14R.apply(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
