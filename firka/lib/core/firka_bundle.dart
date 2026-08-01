import 'package:firka/app/app_state.dart';
import 'package:flutter/services.dart';

class FirkaBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return rootBundle.load(key);
  }
}
