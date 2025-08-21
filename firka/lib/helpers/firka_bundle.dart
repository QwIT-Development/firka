import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:brotli/brotli.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FirkaBundle extends CachingAssetBundle {
  // final bool _compressedBundle = !kDebugMode && Platform.isAndroid;
  final bool _compressedBundle = false;

  Map<String, dynamic>? index;

  Future<Map<String, dynamic>> loadIndex() async {
    var indexBrotli = await rootBundle.load("assets/firka.i");
    var indexStr = brotli.decodeToString(indexBrotli.buffer.asInt8List());

    return Future.value(jsonDecode(indexStr));
  }

  ByteData decode(Codec<List<int>, List<int>> codec, ByteData data) {
    var dec = codec.decode(data.buffer.asInt8List());
    var b = ByteData(dec.length);
    var l = b.buffer.asInt8List();

    for (var i = 0; i < dec.length; i++) {
      l[i] = dec[i];
    }

    return b;
  }

  @override
  Future<ByteData> load(String key) async {
    if (!_compressedBundle) {
      return rootBundle.load(key);
    } else {
      index ??= await loadIndex();

      final gzip = GZipCodec();

      debugPrint("assets/flutter_assets/$key");
      switch (index!["assets/flutter_assets/$key"]!) {
        case "b": // brotli
          return decode(brotli, await rootBundle.load(key));
        case "g": // gzip
          return decode(gzip, await rootBundle.load(key));
        case "r": // raw
          return rootBundle.load(key);
        default:
          throw "Unknown file format: ${index![key]!}";
      }
    }
  }
}
