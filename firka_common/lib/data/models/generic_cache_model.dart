import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

class GenericCacheModel<T extends Identifiable> {
  late Id cacheKey;
  late DateTime createdAt;

  void apply(CacheContext<T> data) {}
}
