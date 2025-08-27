import 'package:isar/isar.dart';

part 'generic_cache_model.g.dart';

enum CacheId { getStudent, getNoticeBoard, getGrades, getOmissions, getTests }

@collection
class GenericCacheModel {
  Id? cacheKey;
  String? cacheData;

  GenericCacheModel();
}
