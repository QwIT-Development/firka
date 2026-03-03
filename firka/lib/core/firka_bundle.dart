import 'package:firka/app/app_state.dart';
import 'package:flutter/services.dart';

class FirkaBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    logger.finest(
      "Loading asset from root bundle: assets/flutter_assets/$key",
    );
    return rootBundle.load(key);
  }
}
