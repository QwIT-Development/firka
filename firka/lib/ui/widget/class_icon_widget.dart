import 'package:firka/helpers/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class ClassIconWidget extends StatelessWidget {
  final String _uid;
  final String _className;
  final String _category;
  final Color color;
  final double? size;

  const ClassIconWidget(
      {super.key,
      required String uid,
      required String className,
      required String category,
      this.color = Colors.white,
      this.size})
      : _className = className,
        _uid = uid,
        _category = category;

  @override
  Widget build(BuildContext context) {
    var iconCategory = getIconType(_uid, _className, _category);

    return Majesticon(getIconData(iconCategory), color: color, size: size);
  }
}
