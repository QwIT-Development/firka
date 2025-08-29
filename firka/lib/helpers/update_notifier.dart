import 'package:flutter/cupertino.dart';

class UpdateNotifier with ChangeNotifier {
  void update() {
    notifyListeners();
  }
}
