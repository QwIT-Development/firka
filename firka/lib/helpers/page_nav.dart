import 'package:flutter/material.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';

class PageNavData {
  final HomePage page;
  final String? subject;
  final String? subjectName;

  PageNavData(this.page, this.subject, this.subjectName);
}

final pageNavNotifier = ValueNotifier<PageNavData?>(null);
