import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qube/utils/helper.dart';

class TimeSlot {
  /// Ожидаем интервалы занятости от сервера. Лучше в UTC-ISO (с 'Z'),
  /// но в любом случае для отображения используем toLocal().
  final DateTime start;
  final DateTime end;
  const TimeSlot(this.start, this.end);
}

class RealtimeClockBooking extends StatefulWidget {
  /// Занятость на день — уже посчитанная СЕРВЕРОМ (с учётом grace и т.п.).
  final List<TimeSlot> busy;

  /// Шаг минут в колесе выбора.
  final Duration minuteStep;

  /// Возвращает ВЫБРАННОЕ время старта в UTC.
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
  DateTime _now = DateTime.now(); // локальное "сейчас"
  late int _selHour;
  late int _selMinute;

  @override
  void initState() {
    super.initState();
    _snapNowToStepAndInit();
    // Обновляем «NOW» раз в 30 секунд и защищаем выбор от прошедшего времени.
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
    return ((m + step - 1) ~/ step) * step; // округление вверх к шагу
  }

  int get _maxMinuteFromNowAbs =>
      _minMinuteFromNow + widget.maxStartAhead.inMinutes;

  DateTime _localMidnight(DateTime base) =>
      DateTime(base.year, base.month, base.day);

  // ---------- занятость (только отображаем то, что пришло с сервера) ----------

  /// Переводим интервалы из widget.busy в минуты локального дня.
  /// Переводим интервалы из widget.busy в минуты локального дня (0..1440),
  /// корректно разбивая интервалы, которые переходят через полночь.
  List<(int, int)> get _busyIntervalsFullDay {
    final result = <(int, int)>[];

    final dayStart = _localMidnight(_now); // сегодня 00:00
    final dayEnd = dayStart.add(const Duration(days: 1)); // завтра 00:00

    for (final slot in widget.busy) {
      // исходные времена в локали (НЕ обрезаем end заранее!)
      final sLocal = slot.start.toLocal();
      final eLocal = slot.end.toLocal();

      // пересекается ли вообще с сегодняшними сутками?
      // (любая часть слота, попадающая в [dayStart, dayEnd + 1д], нам интересна)
      if (eLocal.isBefore(dayStart) || sLocal.isAfter(dayEnd)) {
        // полностью вне сегодняшних суток
        continue;
      }

      // минуты от локальной полуночи БЕЗ обрезки
      //   final startMinutesRaw = _toMinutesOfDay(sLocal);
      final endMinutesRaw = _toMinutesOfDay(eLocal);

      final crossesMidnight =
          eLocal.day != dayStart.day && eLocal.isAfter(sLocal);

      if (!crossesMidnight) {
        // Обычный случай: слот полностью в одних сутках.
        // Пересечение с [dayStart, dayEnd]
        final start = sLocal.isBefore(dayStart) ? dayStart : sLocal;
        final end = eLocal.isAfter(dayEnd) ? dayEnd : eLocal;
        if (!start.isBefore(end)) continue;

        final a = _toMinutesOfDay(start);
        final b = _toMinutesOfDay(end);
        if (a < b) result.add((a, b));
      } else {
        // Слот тянется через полночь.
        // Часть 1: от (максимум из start и сегодня 00:00) до 24:00
        final part1Start = sLocal.isBefore(dayStart) ? dayStart : sLocal;
        if (part1Start.isBefore(dayEnd)) {
          final a = _toMinutesOfDay(part1Start); // 0..1439
          result.add((a, 1440));
        }

        // Часть 2 (на следующий день): 00:00..endMinutesRaw
        // но добавляем её только если «хвост» действительно есть (>00:00)
        if (endMinutesRaw > 0) {
          // эта часть — уже «завтрашняя», но на круге она отображается как 0..end
          result.add((0, endMinutesRaw.clamp(0, 1440)));
        }
      }
    }

    // слияние пересечений
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

    // переводим текущий выбор в "абсолютные" минуты от локальной полуночи текущих суток.
    // если выбранный час меньше minH — считаем, что это "следующие сутки" (после полуночи),
    // но нам достаточно просто привести его обратно в допустимый коридор через часы/минуты.
    int selAbs = _selHour * 60 + _selMinute;
    // Если окно ушло за полночь, и выбор (час) меньше минимального часа, трактуем это как "следующий день"
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
    final minAbs = _minMinuteFromNow; // 0..1439
    final maxAbs = _maxMinuteFromNowAbs; // может быть > 1439

    final minH = minAbs ~/ 60;

    // если конец в те же сутки
    if (maxAbs <= 1439) {
      final maxH = maxAbs ~/ 60;
      // если граница попадает ровно на час — последний час включаем целиком,
      // иначе тоже включаем, но потом ограничим минуты
      return [for (int h = minH; h <= maxH; h++) h];
    }

    // если конец в следующие сутки
    final maxNextAbs = maxAbs - 1440; // 0..?
    final maxHNext = maxNextAbs ~/ 60;

    // часы из текущих суток [minH..23] + часы следующего дня [0..maxHNext]
    return [
      for (int h = minH; h <= 23; h++) h,
      for (int h = 0; h <= maxHNext; h++) h,
    ];
  }

  List<int> _minutesOptionsForHour(int hour) {
    final step = widget.minuteStep.inMinutes;
    final steps = [for (int m = 0; m < 60; m += step) m];

    final minAbs = _minMinuteFromNow; // 0..1439
    final maxAbs = _maxMinuteFromNowAbs; // может быть > 1439

    final minH = minAbs ~/ 60;
    final minMin = minAbs % 60;

    // Верхняя кромка в тех же сутках?
    if (maxAbs <= 1439) {
      final maxH = maxAbs ~/ 60;
      final maxMin = maxAbs % 60;

      if (hour == minH && hour == maxH) {
        // выбран тот же час — минуты от minMin до maxMin включительно
        return steps.where((m) => m >= minMin && m <= maxMin).toList();
      } else if (hour == minH) {
        return steps.where((m) => m >= minMin).toList();
      } else if (hour == maxH) {
        return steps.where((m) => m <= maxMin).toList();
      } else if (hour > minH && hour < maxH) {
        return steps;
      } else {
        return const <int>[]; // вне окна
      }
    }

    // Иначе верхняя кромка — на следующий день
    final maxNextAbs = maxAbs - 1440; // 0..?
    final maxHNext = maxNextAbs ~/ 60;
    final maxMinNext = maxNextAbs % 60;

    // Часы текущих суток
    if (hour >= minH) {
      if (hour == minH) {
        return steps.where((m) => m >= minMin).toList();
      }
      return steps; // между minH+1 и 23 — любые минуты
    }

    // Часы следующего дня: [0..maxHNext]
    if (hour <= maxHNext) {
      if (hour == maxHNext) {
        return steps.where((m) => m <= maxMinNext).toList();
      }
      return steps;
    }

    return const <int>[]; // вне окна
  }

  // ---------- подтверждение (возвращаем UTC) ----------

  Future<void> _confirmAndSubmit() async {
    // локальный выбор пользователя
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
      widget.onConfirm?.call(startUtc); // серверу — UTC
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
          child: CustomPaint(
            painter: _FullDayClockPainter(
              now: _now,
              busy: _busyIntervalsFullDay,
              selectedHour: _selHour,
              selectedMinute: _selMinute,
            ),
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

// ================= Painter =================

class _FullDayClockPainter extends CustomPainter {
  final DateTime now; // локальное "сейчас"
  final List<(int, int)> busy; // интервалы в минутах от локальной полуночи
  final int selectedHour;
  final int selectedMinute;

  _FullDayClockPainter({
    required this.now,
    required this.busy,
    required this.selectedHour,
    required this.selectedMinute,
  });

  int get nowM => now.hour * 60 + now.minute;
  int get selectedM {
    var sel = selectedHour * 60 + selectedMinute;
    // если окно захватывает завтра и выбран час < minHour — добавляем сутки
    if (sel < nowM) sel += 1440;
    return sel;
  }

  @override
  void paint(Canvas canvas, Size size) {
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
        final textOffset =
            center +
            Offset(math.cos(angle), math.sin(angle)) * (radius + 8) -
            Offset(tp.width / 2, tp.height / 2);
        tp.paint(canvas, textOffset);
      }
    }

    // --------- Прошедшее время: от 00:00 текущего дня до now (может >24ч) ----------
    final pastPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white12;

    int nowAbs = nowM;
    // если текущее время + maxStartAhead может переходить на след. сутки, показываем «прошедшее» до now даже если он >1440
    // но само "сейчас" у нас всегда <=1440 (текущий день). Нам нужно, чтобы при выборе окна >24ч
    // дуга корректно шла 0..1440, а потом ещё кусочек 0..(now-1440) если nowAbs>1440
    // но nowAbs сам ≤1440, так что просто если хотим рисовать будущее (например, для визуализации окна),
    // логичнее отложить доп. отрисовку не здесь. Здесь остаёмся в 0..1440.
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

    // Занятые интервалы — красные дуги
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
      if (sweep < 0) sweep += 2 * math.pi; // ← это уже делает переход за 00:00
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
  bool shouldRepaint(covariant _FullDayClockPainter oldDelegate) {
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

// ================= Wheel =================

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
                      color:
                          Colors.white, // если ругнётся, замени на Colors.white
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
