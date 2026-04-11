extension JsonHelper on Map<String, dynamic> {
  double? dbl(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return (value as num).toDouble();
  }

  DateTime? localDate(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String).toLocal();
  }
}
