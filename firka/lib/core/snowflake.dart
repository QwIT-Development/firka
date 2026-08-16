import "dart:math";

/// Local Twitter-style snowflake IDs (64-bit, decimal string).
class Snowflake {
  static const int _epochMs = 1704067200000; // 2024-01-01 UTC
  static final int _workerId = Random().nextInt(1 << 10);
  static int _sequence = 0;
  static int _lastTimestamp = -1;

  static String nextId() {
    var ts = DateTime.now().millisecondsSinceEpoch;
    if (ts < _lastTimestamp) {
      ts = _lastTimestamp;
    }

    if (ts == _lastTimestamp) {
      _sequence = (_sequence + 1) & 0xFFF;
      if (_sequence == 0) {
        while (ts <= _lastTimestamp) {
          ts = DateTime.now().millisecondsSinceEpoch;
        }
      }
    } else {
      _sequence = 0;
    }

    _lastTimestamp = ts;
    final id = ((ts - _epochMs) << 22) | (_workerId << 12) | _sequence;
    return id.toString();
  }
}
