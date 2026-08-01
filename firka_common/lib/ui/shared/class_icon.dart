import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:flutter/material.dart';

import 'package:firka_common/core/icon_helper.dart';
import 'package:firka_common/ui/shared/firka_icon.dart';

import 'package:kreta_api/kreta_api.dart';

class ClassIconWidget extends StatelessWidget {
  final SubjectCacheModel subject;
  final Color color;
  final double? size;

  const ClassIconWidget({
    super.key,
    required SubjectCacheModel this.subject,
    this.color = Colors.white,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    var iconCategory = getIconType(subject);

    return FirkaIconWidget(
      FirkaIconType.majesticons,
      getIconData(iconCategory),
      color: color,
      size: size,
    );
  }
}
