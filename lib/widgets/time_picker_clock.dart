import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qube/utils/helper.dart';

class TimeSlot {
  final DateTime start;
  final DateTime end;
  const TimeSlot(this.start, this.end);
}

class RealtimeClockBooking extends StatefulWidget {
  final List<TimeSlot> busy;
  final Duration minuteStep;
  final void Function(DateTime startUtc)? onConfirm;
  final VoidCallback? onCancel;
  final double clockSize;
  final Duration maxStartAhead;

  const RealtimeClockBooking({
    super.key,
    required this.busy,
    this.minuteStep = const Duration(minutes: 15),
    this.onConfirm,
    this.onCancel,
    this.clockSize = 220,
    this.maxStartAhead = const Duration(hours: 12),
  });

  @override
  State<RealtimeClockBooking> createState() => _RealtimeClockBookingState();
}

class _RealtimeClockBookingState extends State<RealtimeClockBooking> {
  late Timer _ticker;
  DateTime _now = DateTime.now();
  late int _selHour;
  late int _selMinute;

  @override
  void initState() {
    super.initState();
    _snapNowToStepAndInit();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      final prevMinute = _now.minute;
      _now = DateTime.now();
      if (_now.minute != prevMinute) setStateSafe(() {});
      _guardSelectionWithinBounds();
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  // ---------- helpers ----------

  int _toMinutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;

  int get _minMinuteFromNow {
    final step = widget.minuteStep.inMinutes;
    final m = _toMinutesOfDay(_now);
    return ((m + step - 1) ~/ step) * step;
  }

  int get _maxMinuteFromNowAbs =>
      _minMinuteFromNow + widget.maxStartAhead.inMinutes;

  DateTime _localMidnight(DateTime base) =>
      DateTime(base.year, base.month, base.day);

  // ---------- занятость ----------

  List<(int, int)> get _busyIntervalsFullDay {
    final result = <(int, int)>[];
    final dayStart = _localMidnight(_now);
    final dayEnd = dayStart.add(const Duration(days: 1));

    for (final slot in widget.busy) {
      final sLocal = slot.start.toLocal();
      final eLocal = slot.end.toLocal();

      if (eLocal.isBefore(dayStart) || sLocal.isAfter(dayEnd)) {
        continue;
      }

      final endMinutesRaw = _toMinutesOfDay(eLocal);
      final crossesMidnight =
          eLocal.day != dayStart.day && eLocal.isAfter(sLocal);

      if (!crossesMidnight) {
        final start = sLocal.isBefore(dayStart) ? dayStart : sLocal;
        final end = eLocal.isAfter(dayEnd) ? dayEnd : eLocal;
        if (!start.isBefore(end)) continue;

        final a = _toMinutesOfDay(start);
        final b = _toMinutesOfDay(end);
        if (a < b) result.add((a, b));
      } else {
        final part1Start = sLocal.isBefore(dayStart) ? dayStart : sLocal;
        if (part1Start.isBefore(dayEnd)) {
          final a = _toMinutesOfDay(part1Start);
          result.add((a, 1440));
        }

        if (endMinutesRaw > 0) {
          result.add((0, endMinutesRaw.clamp(0, 1440)));
        }
      }
    }

    result.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(int, int)>[];
    for (final it in result) {
      if (merged.isEmpty) {
        merged.add(it);
      } else {
        final last = merged.last;
        if (it.$1 <= last.$2) {
          merged[merged.length - 1] = (last.$1, math.max(last.$2, it.$2));
        } else {
          merged.add(it);
        }
      }
    }
    return merged;
  }

  bool get _selectionBusy {
    final selectedMinutes = _selHour * 60 + _selMinute;
    for (final (start, end) in _busyIntervalsFullDay) {
      if (selectedMinutes >= start && selectedMinutes < end) return true;
    }
    return false;
  }

  // ---------- выбор времени ----------

  void _snapNowToStepAndInit() {
    final minM = _minMinuteFromNow;
    _selHour = minM ~/ 60;
    _selMinute = minM % 60;
  }

  void _guardSelectionWithinBounds() {
    final minAbs = _minMinuteFromNow;
    final maxAbs = _maxMinuteFromNowAbs;

    int selAbs = _selHour * 60 + _selMinute;
    if (selAbs < minAbs && maxAbs > 1439) {
      selAbs += 1440;
    }

    int clamped = selAbs.clamp(minAbs, maxAbs);
    if (clamped != selAbs) {
      final h = (clamped % 1440) ~/ 60;
      final m = (clamped % 1440) % 60;
      _selHour = h;
      _selMinute = m;
      setStateSafe(() {});
    }
  }

  List<int> _hoursOptions() {
    final minAbs = _minMinuteFromNow;
    final maxAbs = _maxMinuteFromNowAbs;
    final minH = minAbs ~/ 60;

    if (maxAbs <= 1439) {
      final maxH = maxAbs ~/ 60;
      return [for (int h = minH; h <= maxH; h++) h];
    }

    final maxNextAbs = maxAbs - 1440;
    final maxHNext = maxNextAbs ~/ 60;

    return [
      for (int h = minH; h <= 23; h++) h,
      for (int h = 0; h <= maxHNext; h++) h,
    ];
  }

  List<int> _minutesOptionsForHour(int hour) {
    final step = widget.minuteStep.inMinutes;
    final steps = [for (int m = 0; m < 60; m += step) m];

    final minAbs = _minMinuteFromNow;
    final maxAbs = _maxMinuteFromNowAbs;
    final minH = minAbs ~/ 60;
    final minMin = minAbs % 60;

    if (maxAbs <= 1439) {
      final maxH = maxAbs ~/ 60;
      final maxMin = maxAbs % 60;

      if (hour == minH && hour == maxH) {
        return steps.where((m) => m >= minMin && m <= maxMin).toList();
      } else if (hour == minH) {
        return steps.where((m) => m >= minMin).toList();
      } else if (hour == maxH) {
        return steps.where((m) => m <= maxMin).toList();
      } else if (hour > minH && hour < maxH) {
        return steps;
      } else {
        return const <int>[];
      }
    }

    final maxNextAbs = maxAbs - 1440;
    final maxHNext = maxNextAbs ~/ 60;
    final maxMinNext = maxNextAbs % 60;

    if (hour >= minH) {
      if (hour == minH) {
        return steps.where((m) => m >= minMin).toList();
      }
      return steps;
    }

    if (hour <= maxHNext) {
      if (hour == maxHNext) {
        return steps.where((m) => m <= maxMinNext).toList();
      }
      return steps;
    }

    return const <int>[];
  }

  // ---------- подтверждение ----------

  Future<void> _confirmAndSubmit() async {
    final startLocal = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _selHour,
      _selMinute,
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Подтверждение',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы хотите забронировать:\n'
          '${startLocal.day.toString().padLeft(2, '0')}.'
          '${startLocal.month.toString().padLeft(2, '0')}.'
          '${startLocal.year} в '
          '${startLocal.hour.toString().padLeft(2, '0')}:'
          '${startLocal.minute.toString().padLeft(2, '0')} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final startUtc = startLocal.toUtc();
      widget.onConfirm?.call(startUtc);
      if (context.mounted && mounted) Navigator.of(context).maybePop();
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final hours = _hoursOptions();
    if (!hours.contains(_selHour)) {
      _selHour = hours.first;
      final mins = _minutesOptionsForHour(_selHour);
      _selMinute = mins.first;
    }
    final minutes = _minutesOptionsForHour(_selHour);
    if (!minutes.contains(_selMinute)) _selMinute = minutes.first;

    final selectedBusy = _selectionBusy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.clockSize,
          height: widget.clockSize,
          child: _OptimizedClockPainter(
            now: _now,
            busy: _busyIntervalsFullDay,
            selectedHour: _selHour,
            selectedMinute: _selMinute,
            clockSize: widget.clockSize,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                child: _Wheel<int>(
                  label: 'Часы',
                  items: hours,
                  selected: _selHour,
                  itemToString: (h) => h.toString().padLeft(2, '0'),
                  onChanged: (h) => setStateSafe(() => _selHour = h),
                ),
              ),
              Expanded(
                child: _Wheel<int>(
                  label: 'Минуты',
                  items: minutes,
                  selected: _selMinute,
                  itemToString: (m) => m.toString().padLeft(2, '0'),
                  onChanged: (m) => setStateSafe(() => _selMinute = m),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: selectedBusy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.block, color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Время занято',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selHour.toString().padLeft(2, '0')}:${_selMinute.toString().padLeft(2, '0')} свободно',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Отмена'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedBusy ? null : _confirmAndSubmit,
                      icon: const Icon(Icons.check),
                      label: const Text('Забронировать'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================= ОПТИМИЗИРОВАННЫЙ PAINTER =================

class _OptimizedClockPainter extends StatelessWidget {
  final DateTime now;
  final List<(int, int)> busy;
  final int selectedHour;
  final int selectedMinute;
  final double clockSize;

  const _OptimizedClockPainter({
    required this.now,
    required this.busy,
    required this.selectedHour,
    required this.selectedMinute,
    required this.clockSize,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ClockStaticPainter(),
        foregroundPainter: _ClockDynamicPainter(
          now: now,
          busy: busy,
          selectedHour: selectedHour,
          selectedMinute: selectedMinute,
        ),
        size: Size.square(clockSize),
      ),
    );
  }
}

// 1) Статический painter - никогда не перерисовывается
class _ClockStaticPainter extends CustomPainter {
  static ui.Picture? _cachedStaticPicture;
  static double _lastClockSize = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final clockSize = size.width;

    // Кэшируем Picture только если размер изменился
    if (_cachedStaticPicture == null || _lastClockSize != clockSize) {
      _lastClockSize = clockSize;
      _cachedStaticPicture = _createStaticPicture(clockSize);
    }

    canvas.drawPicture(_cachedStaticPicture!);
  }

  ui.Picture _createStaticPicture(double clockSize) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size.square(clockSize);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    // Фон циферблата
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFF2C2F3A);
    canvas.drawCircle(center, radius, backgroundPaint);

    // Часовые метки
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white70;

    // Кэш для TextPainter'ов
    final textPainters = <int, TextPainter>{};

    for (int hour = 0; hour < 24; hour++) {
      final angle = _angleFromMinutes(hour * 60);
      final startPoint =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 10);
      final endPoint =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 2);
      canvas.drawLine(startPoint, endPoint, tickPaint);

      if (hour % 3 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: hour.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainters[hour] = tp;

        final textOffset =
            center +
            Offset(math.cos(angle), math.sin(angle)) * (radius + 8) -
            Offset(tp.width / 2, tp.height / 2);
        tp.paint(canvas, textOffset);
      }
    }

    return recorder.endRecording();
  }

  double _angleFromMinutes(int minutes) =>
      -math.pi / 2 + 2 * math.pi * (minutes / 1440.0);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2) Динамический painter - только для изменяющихся элементов
class _ClockDynamicPainter extends CustomPainter {
  final DateTime now;
  final List<(int, int)> busy;
  final int selectedHour;
  final int selectedMinute;

  _ClockDynamicPainter({
    required this.now,
    required this.busy,
    required this.selectedHour,
    required this.selectedMinute,
  });

  int get nowM => now.hour * 60 + now.minute;
  int get selectedM {
    var sel = selectedHour * 60 + selectedMinute;
    if (sel < nowM) sel += 1440;
    return sel;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    // Дуга прошедшего времени
    final pastPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white12;

    int nowAbs = nowM;
    final startAngle = _angleFromMinutes(0);
    final nowAngle = _angleFromMinutes(nowAbs);
    double sweepAngle = nowAngle - startAngle;
    if (sweepAngle < 0) sweepAngle += 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      pastPaint,
    );

    // Занятые интервалы
    final busyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = Colors.red.withValues(alpha: 0.8);

    for (final (start, end) in busy) {
      if (start >= end) continue;
      final sa = _angleFromMinutes(start);
      final ea = _angleFromMinutes(end);
      double sweep = ea - sa;
      if (sweep < 0) sweep += 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sa,
        sweep,
        false,
        busyPaint,
      );
    }

    // Линия текущего времени
    final nowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.yellow;
    final nowAngleLine = _angleFromMinutes(nowM);
    final nowEndPoint =
        center +
        Offset(math.cos(nowAngleLine), math.sin(nowAngleLine)) * (radius - 18);
    canvas.drawLine(center, nowEndPoint, nowPaint);

    // Текст "NOW"
    final nowText = TextPainter(
      text: const TextSpan(
        text: 'NOW',
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nowText.paint(canvas, nowEndPoint - const Offset(12, 18));

    // Линия выбранного времени
    final selPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.green;
    final selAngle = _angleFromMinutes(selectedM % 1440);
    final selEndPoint =
        center + Offset(math.cos(selAngle), math.sin(selAngle)) * (radius - 18);
    canvas.drawLine(center, selEndPoint, selPaint);

    // Текст выбранного времени
    final selText = TextPainter(
      text: TextSpan(
        text:
            '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    selText.paint(canvas, selEndPoint - Offset(selText.width / 2, 18));

    // Центральная точка
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  double _angleFromMinutes(int minutes) =>
      -math.pi / 2 + 2 * math.pi * (minutes / 1440.0);

  @override
  bool shouldRepaint(covariant _ClockDynamicPainter oldDelegate) {
    return oldDelegate.now.minute != now.minute ||
        !_listEquals(oldDelegate.busy, busy) ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute;
  }

  bool _listEquals(List<(int, int)> a, List<(int, int)> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }
}

// ================= Wheel (без изменений) =================

class _Wheel<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T selected;
  final String Function(T) itemToString;
  final ValueChanged<T> onChanged;

  const _Wheel({
    required this.label,
    required this.items,
    required this.selected,
    required this.itemToString,
    required this.onChanged,
  });

  @override
  State<_Wheel<T>> createState() => _WheelState<T>();
}

class _WheelState<T> extends State<_Wheel<T>> {
  late FixedExtentScrollController _ctrl;
  int _lastIndex = 0;
  bool _userScrolling = false;

  int _indexForSelected() {
    final index = widget.items.indexOf(widget.selected);
    return index.clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _lastIndex = _indexForSelected();
    _ctrl = FixedExtentScrollController(initialItem: _lastIndex);
  }

  @override
  void didUpdateWidget(covariant _Wheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _indexForSelected();
    if (!_userScrolling && targetIndex != _lastIndex) {
      final delta = (targetIndex - _lastIndex).abs();
      final durationMs = (140 + 90 * (delta > 4 ? 4 : delta)).toInt();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _ctrl.animateToItem(
            targetIndex,
            duration: Duration(milliseconds: durationMs),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {
          _ctrl.jumpToItem(targetIndex);
        }
      });
      _lastIndex = targetIndex;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _userScrolling = true;
              }
              if (notification is ScrollEndNotification) _userScrolling = false;
              return false;
            },
            child: CupertinoPicker(
              itemExtent: 34,
              squeeze: 1.07,
              diameterRatio: 1.5,
              useMagnifier: true,
              magnification: 1.12,
              scrollController: _ctrl,
              onSelectedItemChanged: (index) {
                HapticFeedback.selectionClick();
                _lastIndex = index;
                widget.onChanged(widget.items[index]);
              },
              children: widget.items.map((item) {
                return Center(
                  child: Text(
                    widget.itemToString(item),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
