DateTime? debugFakeTime;
DateTime? debugSetAt;
var debugTimeAdvance = false;

DateTime timeNow() {
  if (debugFakeTime != null) {
    if (debugTimeAdvance && debugSetAt != null) {
      var diff = DateTime.now().difference(debugSetAt!);

      return debugFakeTime!.add(diff);
    } else {
      return debugFakeTime!;
    }
  } else {
    return DateTime.now();
  }
}
