String formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return "${two(dt.day)}.${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}";
}

String readableDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0 && m > 0) return "$hч $mм";
  if (h > 0) return "$hч";
  return "$mм";
} // TODO Implement this library.
