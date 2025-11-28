import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';

bool listEqualsById(List<Computer> a, List<Computer> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}

TimeOfDay? parseHm(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

String hmPretty(String? s) => s ?? '';

DateTime combine(DateTime base, TimeOfDay tod) =>
    DateTime(base.year, base.month, base.day, tod.hour, tod.minute);

class FixedWindow {
  final DateTime startBoundary;
  final DateTime endBoundary;
  FixedWindow(this.startBoundary, this.endBoundary);
}

FixedWindow? computeNextFixedWindow(String? startAt, String? endAt) {
  final s = parseHm(startAt);
  final e = parseHm(endAt);
  if (s == null || e == null) return null;

  final now = DateTime.now();
  final todayStart = combine(now, s);
  var todayEnd = combine(now, e);

  final crossesMidnight =
      (e.hour < s.hour) || (e.hour == s.hour && e.minute <= s.minute);
  if (crossesMidnight && !todayEnd.isAfter(todayStart)) {
    todayEnd = todayEnd.add(const Duration(days: 1));
  }

  if (now.isBefore(todayStart)) {
    return FixedWindow(todayStart, todayEnd);
  }

  if (now.isBefore(todayEnd)) {
    return FixedWindow(todayStart, todayEnd);
  }

  final tomorrow = now.add(const Duration(days: 1));
  final nextStart = combine(tomorrow, s);
  var nextEnd = combine(tomorrow, e);
  if (crossesMidnight && !nextEnd.isAfter(nextStart)) {
    nextEnd = nextEnd.add(const Duration(days: 1));
  }
  return FixedWindow(nextStart, nextEnd);
}
