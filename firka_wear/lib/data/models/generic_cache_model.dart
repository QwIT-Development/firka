import 'package:isar_community/isar.dart';

part 'generic_cache_model.g.dart';

enum CacheId {
  getStudent,
  getNoticeBoard,
  getGrades,
  getOmissions,
  getTests,
  wearSyncMetadata,
  wearSyncTimetable,
}

@collection
class GenericCacheModel {
  Id? cacheKey;
  String? cacheData;

  GenericCacheModel();
}
