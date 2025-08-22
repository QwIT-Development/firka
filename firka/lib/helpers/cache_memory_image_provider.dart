import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Taken from https://gist.github.com/darmawan01/9be266df44594ea59f07032e325ffa3b
// and adapted to use assets

final _globalImageCache = <String, Uint8List>{};

Future<void> precacheAsset(AssetBundle bundle, String asset) async {
  if (!_globalImageCache.containsKey(asset)) {
    final data = await bundle.load(asset);
    _globalImageCache[asset] = data.buffer.asUint8List();
  }
}

Future<void> precacheAssets(AssetBundle bundle, List<String> assets) async {
  for (final asset in assets) {
    await precacheAsset(bundle, asset);
  }
}

Future<Uint8List> _cacheLoad(AssetBundle bundle, String asset) async {
  if (!_globalImageCache.containsKey(asset)) {
    final data = await bundle.load(asset);
    _globalImageCache[asset] = data.buffer.asUint8List();
  }

  return Future.value(_globalImageCache[asset]!);
}

class CacheMemoryImageProvider extends ImageProvider<CacheMemoryImageProvider> {
  final AssetBundle bundle;
  final String path;
  Uint8List? _img;

  CacheMemoryImageProvider(this.bundle, this.path);

  @override
  ImageStreamCompleter loadImage(
      CacheMemoryImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
      debugLabel: path,
      informationCollector: () sync* {
        yield ErrorDescription('Tag: $path');
      },
    );
  }

  Future<Codec> _loadAsync(ImageDecoderCallback decode) async {
    _img ??= await _cacheLoad(bundle, path);

    // the DefaultCacheManager() encapsulation, it get cache from local storage.
    final Uint8List bytes = _img!;

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(this);
      throw StateError('$path is empty and cannot be loaded as an image.');
    }
    final buffer = await ImmutableBuffer.fromUint8List(bytes);

    return await decode(buffer);
  }

  @override
  Future<CacheMemoryImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CacheMemoryImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is CacheMemoryImageProvider && other.path == path;
    return res;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CacheImageProvider')}("$path")';
}
