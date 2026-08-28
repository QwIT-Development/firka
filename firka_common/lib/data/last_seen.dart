import 'package:firka_common/data/models/generic_cache_model.dart';

class LastSeen {
  final DateTime createdAt;
  final int cacheKey;

  const LastSeen(this.createdAt, this.cacheKey);

  static LastSeen? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split(":");
    if (parts.length != 2) return null;

    final millis = int.tryParse(parts[0]);
    final key = int.tryParse(parts[1]);
    if (millis == null || key == null) return null;

    return LastSeen(DateTime.fromMillisecondsSinceEpoch(millis), key);
  }

  static LastSeen? newestOf(Iterable<GenericCacheModel> items) {
    LastSeen? newest;
    for (final item in items) {
      final seen = LastSeen(item.createdAt, item.cacheKey);
      if (newest == null || seen.isAfter(newest)) newest = seen;
    }
    return newest;
  }

  static List<T> newerThan<T extends GenericCacheModel>(
    Iterable<T> items,
    LastSeen? seen,
  ) {
    if (seen == null) return items.toList();

    return items
        .where((i) => LastSeen(i.createdAt, i.cacheKey).isAfter(seen))
        .toList();
  }

  bool isAfter(LastSeen other) {
    if (createdAt.isAfter(other.createdAt)) return true;
    if (createdAt.isAtSameMomentAs(other.createdAt)) {
      return cacheKey > other.cacheKey;
    }
    return false;
  }

  String toText() => "${createdAt.millisecondsSinceEpoch}:$cacheKey";
}
