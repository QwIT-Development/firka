import 'package:flutter/material.dart';

class UpdateNotifier with ChangeNotifier {
  void update() {
    notifyListeners();
  }
}
