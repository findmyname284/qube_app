import 'package:flutter/material.dart';
import 'package:qube/utils/date_utils.dart';
import 'package:qube/screens/computers/widgets/duration_slider.dart';

Future<Duration?> showDurationPickerSheet(
  BuildContext context,
  DateTime start, {
  required bool isNightTariff,
  required int maxHours,
  required Duration rollingWindow,
}) {
  final maxDur = _maxDurationForStart(
    start,
    isNightTariff: isNightTariff,
    maxHours: maxHours,
    rollingWindow: rollingWindow,
  );

  if (maxDur <= Duration.zero) {
    return Future.value(null);
  }

  Duration current = const Duration(hours: 1);
  if (current > maxDur) current = maxDur;

  final now = DateTime.now();

  return showModalBottomSheet<Duration>(
    context: context,
    backgroundColor: const Color(0xFF1E1F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setStateSB) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Длительность",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Максимум: ${readableDuration(maxDur)} (окно до ${formatDateTime(now.add(rollingWindow))})",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                DurationSlider(
                  value: current,
                  max: maxDur,
                  onChanged: (d) => setStateSB(() => current = d),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text("Отмена"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, current),
                        child: Text("OK • ${readableDuration(current)}"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Duration _maxDurationForStart(
  DateTime start, {
  required bool isNightTariff,
  required int maxHours,
  required Duration rollingWindow,
}) {
  final now = DateTime.now();
  final endWindow = now.add(rollingWindow);
  final capByWindow = endWindow.isBefore(start)
      ? Duration.zero
      : endWindow.difference(start);
  const capBy12h = Duration(hours: _maxHours);

  Duration? capByNight;
  if (isNightTariff) {
    late DateTime nightEnd;
    if (start.hour >= 22) {
      final nextDay = start.add(const Duration(days: 1));
      nightEnd = DateTime(nextDay.year, nextDay.month, nextDay.day, 8, 0);
    } else if (start.hour < 8) {
      nightEnd = DateTime(start.year, start.month, start.day, 8, 0);
    } else {
      nightEnd = start;
    }
    capByNight = nightEnd.isAfter(start)
        ? nightEnd.difference(start)
        : Duration.zero;
  }

  Duration maxDur = capByWindow < capBy12h ? capByWindow : capBy12h;
  if (isNightTariff && capByNight != null) {
    maxDur = capByNight < maxDur ? capByNight : maxDur;
  }
  if (maxDur.isNegative) return Duration.zero;
  return maxDur;
}

const int _maxHours = 12;
