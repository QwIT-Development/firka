import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ImagePreloader {
  static final Map<String, ui.Image> _cache = {};
  static final Map<String, Future<ui.Image>> _loadingFutures = {};

  static Future<ui.Image> preloadAssetImage(
      AssetBundle bundle, String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath]!;
    }

    if (_loadingFutures.containsKey(assetPath)) {
      return _loadingFutures[assetPath]!;
    }

    final future = _loadAssetImage(bundle, assetPath);
    _loadingFutures[assetPath] = future;

    try {
      final image = await future;
      _cache[assetPath] = image;
      return image;
    } finally {
      _loadingFutures.remove(assetPath);
    }
  }

  static Future<ui.Image> preloadNetworkImage(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    if (_loadingFutures.containsKey(url)) {
      return _loadingFutures[url]!;
    }

    final future = _loadNetworkImage(url);
    _loadingFutures[url] = future;

    try {
      final image = await future;
      _cache[url] = image;
      return image;
    } finally {
      _loadingFutures.remove(url);
    }
  }

  static Future<List<ui.Image>> preloadMultipleAssets(
      AssetBundle bundle, List<String> assetPaths) async {
    final futures =
        assetPaths.map((path) => preloadAssetImage(bundle, path)).toList();
    return await Future.wait(futures);
  }

  static Future<List<ui.Image>> preloadWithProgress(
    AssetBundle bundle,
    List<String> assetPaths,
    Function(int loaded, int total)? onProgress,
  ) async {
    final List<ui.Image> results = [];

    for (int i = 0; i < assetPaths.length; i++) {
      final image = await preloadAssetImage(bundle, assetPaths[i]);
      results.add(image);
      onProgress?.call(i + 1, assetPaths.length);
    }

    return results;
  }

  static ui.Image? getCachedImage(String key) {
    return _cache[key];
  }

  static bool isCached(String key) {
    return _cache.containsKey(key);
  }

  static int getCacheSize() {
    return _cache.length;
  }

  static void clearImage(String key) {
    _cache.remove(key);
  }

  static void clearCache() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _loadingFutures.clear();
  }

  static void trimCache(int maxSize) {
    if (_cache.length <= maxSize) return;

    final keys = _cache.keys.toList();
    final keysToRemove = keys.take(_cache.length - maxSize);

    for (final key in keysToRemove) {
      _cache[key]?.dispose();
      _cache.remove(key);
    }
  }

  static Future<ui.Image> _loadAssetImage(
      AssetBundle bundle, String assetPath) async {
    final ByteData data = await bundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    return await _decodeImageFromBytes(bytes);
  }

  static Future<ui.Image> _loadNetworkImage(String url) async {
    throw UnimplementedError(
        'Network image loading not implemented in this example');
  }

  static Future<ui.Image> _decodeImageFromBytes(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}

// NOTE: Only works on non animated images.
class PreloadedImageProvider extends ImageProvider<PreloadedImageProvider> {
  final AssetBundle assetBundle;
  final String assetPath;

  const PreloadedImageProvider(this.assetBundle, this.assetPath);

  @override
  Future<PreloadedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PreloadedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      PreloadedImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key));
  }

  Future<ImageInfo> _loadAsync(PreloadedImageProvider key) async {
    // clone the image before using it to prevent from the original image
    // getting disposed
    final cachedImage = ImagePreloader.getCachedImage(key.assetPath)?.clone();

    if (cachedImage != null) {
      return ImageInfo(image: cachedImage);
    }

    try {
      final image =
          await ImagePreloader.preloadAssetImage(assetBundle, key.assetPath);
      return ImageInfo(image: image.clone());
    } catch (e) {
      final ByteData data = await assetBundle.load(key.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return ImageInfo(image: frameInfo.image.clone());
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is PreloadedImageProvider && other.assetPath == assetPath;
  }

  @override
  int get hashCode => assetPath.hashCode;

  @override
  String toString() => 'PreloadedImageProvider("$assetPath")';
}
