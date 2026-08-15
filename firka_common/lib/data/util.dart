import 'dart:math';

import 'package:firka_common/data/cache_manager.dart';
import 'package:firka_common/data/database.dart';
import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:isar_community/isar.dart';

import 'package:kreta_api/kreta_api.dart';

int genCacheKey(DateTime date, int studentId) {
  var md = date.month * pow(10, 2) + date.day;

  return (md * pow(10, 11) + studentId) as int;
}

DateTime getDate(int key) {
  var md = key ~/ pow(10, 11);
  var month = md ~/ pow(10, 2);
  var day = (md - month * pow(10, 2)) as int;

  return DateTime(DateTime.now().year, month, day);
}

class CacheContext<T extends Identifiable> {
  final CacheManager cacheManager;
  final T data;

  CacheContext(this.cacheManager, this.data);
}

extension LinksExtension<M> on IsarLinks<M> {
  Set<M> loadAndGet() {
    if (!isAttached) {
      print("${this}: Isar link got before attached");
    }
    if (!isLoaded) {
      loadSync();
    }
    // can be useful for debugging
    /*if (value == null) {
      print("${M} link: null value detected");
    }*/
    return this;
  }
}

extension LinkExtension<T extends Identifiable, M extends GenericCacheModel<T>>
    on IsarLink<M> {
  M? loadAndGet() {
    if (!isAttached) {
      print("${this}: Isar link got before attached");
    }
    if (!isLoaded) {
      loadSync();
    }
    // can be useful for debugging
    /*if (value == null) {
      print("${M} link: null value detected");
    }*/
    return value;
  }

  /// Attaches by id and if the object is absent makes one
  void init(CacheManager manager, T? t) {
    if (t == null) {
      return;
    }
    value = isarInit.collection<M>().getSync(manager.genCacheKey(t));
  }

  /// Does not creates an object, only attempts to attach by id
  /// if you want to create with it, use `init` instead
  void unsafeInit(CacheManager manager, Identifiable? identifiable) {
    if (identifiable == null) {
      return;
    }
    value = isarInit.collection<M>().getSync(manager.genCacheKey(identifiable));
  }
}
