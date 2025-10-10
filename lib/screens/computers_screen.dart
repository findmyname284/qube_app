import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/tariff.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';
import 'package:qube/widgets/computer_card.dart';
import 'package:qube/widgets/computer_marker.dart';
import 'package:qube/widgets/computer_details_sheet.dart';
import 'package:qube/widgets/duration_slider.dart';
import 'package:qube/widgets/list_skeleton.dart';
import 'package:qube/utils/date_utils.dart';
import 'package:qube/models/booking_models.dart';
import 'package:qube/widgets/time_picker_clock.dart';
import 'package:qube/utils/helper.dart';

final api = ApiService.instance;

class ComputersScreen extends StatefulWidget {
  final List<Computer> computers;
  final bool isMapView;
  final Function(bool isMap) onMapModeChanged;
  final VoidCallback onToggleView;
  final Function(bool visible) onFabVisibilityChanged;

  const ComputersScreen({
    super.key,
    required this.computers,
    required this.isMapView,
    required this.onMapModeChanged,
    required this.onToggleView,
    required this.onFabVisibilityChanged,
  });

  @override
  State<ComputersScreen> createState() => _ComputersScreenState();
}

class _ComputersScreenState extends State<ComputersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final ScrollController _scrollController;

  final double cellSize = 75;

  bool isLoading = true;
  bool isRefreshing = false;
  late List<Computer> _computers;

  static const int _maxHours = 12;
  static const Duration _rollingWindow = Duration(hours: 24);

  @override
  void initState() {
    super.initState();

    _computers = widget.computers;
    isLoading = _computers.isEmpty;

    _scrollController = ScrollController()..addListener(_scrollListener);

    _sheetController = BottomSheet.createAnimationController(this)
      ..duration = const Duration(milliseconds: 380)
      ..reverseDuration = const Duration(milliseconds: 280);

    final curved = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

    if (isLoading) {
      Future.microtask(_refreshInitial);
    } else {
      _softRefreshInBackground();
    }
  }

  @override
  void didUpdateWidget(covariant ComputersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.computers != widget.computers) {
      setStateSafe(() {
        _computers = widget.computers;
        isLoading = _computers.isEmpty;
      });
      if (_computers.isEmpty) _refreshInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ---------- DATA LOADING ----------

  Future<void> _refreshInitial() async {
    setStateSafe(() => isLoading = true);
    try {
      final list = await api.fetchComputers();
      setStateSafe(() => _computers = list);
    } finally {
      if (mounted) setStateSafe(() => isLoading = false);
    }
  }

  Future<void> _softRefreshInBackground() async {
    try {
      final list = await api.fetchComputers();
      if (!mounted) return;
      _applyDiffUpdate(list);
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _refresh() async {
    if (isRefreshing) return;
    setStateSafe(() => isRefreshing = true);
    try {
      final list = await api.fetchComputers();
      if (!mounted) return;
      _applyDiffUpdate(list);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: "Ошибка обновления: $e",
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setStateSafe(() => isRefreshing = false);
    }
  }

  void _applyDiffUpdate(List<Computer> fresh) {
    fresh.sort((a, b) => a.id.compareTo(b.id));

    final sameLength = fresh.length == _computers.length;
    bool identicalLists = sameLength;
    if (sameLength) {
      for (var i = 0; i < fresh.length; i++) {
        final a = fresh[i];
        final b = _computers[i];
        if (a.id != b.id ||
            a.status != b.status ||
            a.zone != b.zone ||
            a.x != b.x ||
            a.y != b.y) {
          identicalLists = false;
          break;
        }
      }
    } else {
      identicalLists = false;
    }

    if (!identicalLists) {
      setStateSafe(() => _computers = fresh);
    }
  }

  // ---------- SCROLL / FAB ----------

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final screenHeight = MediaQuery.of(context).size.height;

    if (maxScroll - currentScroll < screenHeight * 0.3) {
      widget.onFabVisibilityChanged(false);
    } else {
      widget.onFabVisibilityChanged(true);
    }
  }

  // ---------- UI PIECES ----------

  Color _statusColor(String s) => s == "free"
      ? const Color(0xFF00B894)
      : s == "booked"
      ? const Color(0xFFFFC048)
      : const Color(0xFFFF7676);

  Widget _buildTopProgress() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isRefreshing ? 2.5 : 0,
      child: isRefreshing
          ? const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              minHeight: 2.5,
            )
          : const SizedBox.shrink(),
    );
  }

  // --- LIST ---

  Widget _buildListView() {
    if (isLoading) {
      return const ListSkeleton();
    }

    if (_computers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Нет данных о компьютерах",
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF6C5CE7),
      child: AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            bottom: kBottomNavigationBarHeight + 32,
            top: 8,
          ),
          itemCount: _computers.length,
          itemBuilder: (context, index) {
            final comp = _computers[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 260),
              child: SlideAnimation(
                verticalOffset: 36.0,
                child: FadeInAnimation(
                  child: ComputerCard(
                    key: ValueKey(comp.id),
                    comp: comp,
                    onTap: () => _showComputerDetails(context, comp),
                    statusColor: _statusColor(comp.status),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MAP ---

  Widget _buildMapView() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    if (_computers.isEmpty) {
      return const Center(
        child: Text(
          "Нет компьютеров для отображения",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final maxX = _computers.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = _computers.map((c) => c.y).reduce((a, b) => a > b ? a : b);
    final fieldWidth = (maxX + 3) * cellSize;
    final fieldHeight = (maxY + 3) * cellSize;

    return Stack(
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 2.5,
            child: SizedBox(
              width: fieldWidth,
              height: fieldHeight,
              child: Stack(
                children: _computers
                    .map(
                      (c) => ComputerMarker(
                        key: ValueKey(c.id),
                        comp: c,
                        cellSize: cellSize,
                        color: _statusColor(c.status),
                        onTap: () => _showComputerDetails(context, c),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _buildTopProgress()),
      ],
    );
  }

  // --- BOTTOM SHEET ---

  void _showComputerDetails(BuildContext context, Computer comp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      transitionAnimationController: _sheetController,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ComputerDetailsSheet(
          fade: _fade,
          slide: _slide,
          computer: comp,
          statusColor: _statusColor(comp.status),
          onBook: _bookComputer,
          onUnbook: _unbookComputer,
        );
      },
    );
  }

  // ---------- NEW: TARIF PICKER ----------

  Future<Tariff?> _pickTariff(Computer comp) async {
    return showModalBottomSheet<Tariff>(
      context: context,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        Tariff? selected;

        // ограничим высоту, чтобы список не рос бесконечно
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.66;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Выбор тарифа",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comp.zone.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Tariff>>(
                  future: api.fetchTariffsForComputer(comp.id),
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Не удалось загрузить тарифы: ${snap.error}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final tariffs = snap.data ?? const <Tariff>[];
                    if (tariffs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Для этой зоны тарифов нет.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return StatefulBuilder(
                      builder: (ctx2, setStateSB) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxHeight,
                            minHeight: 0,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: tariffs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = tariffs[i];
                              final fixed = t.minutes > 0;
                              final selectedNow = selected?.id == t.id;

                              return InkWell(
                                onTap: () => setStateSB(() => selected = t),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF23243A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedNow
                                          ? const Color(0xFF6C5CE7)
                                          : Colors.white.withOpacity(.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<Tariff>(
                                        value: t,
                                        groupValue: selected,
                                        onChanged: (val) =>
                                            setStateSB(() => selected = val),
                                        fillColor: MaterialStateProperty.all(
                                          const Color(0xFF6C5CE7),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    t.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "${t.price} ₸",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              t.description.isNotEmpty
                                                  ? t.description
                                                  : (fixed
                                                        ? "${t.minutes} мин"
                                                        : "Свободная длительность"),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (t.discountApplied > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF00B894,
                                                        ).withOpacity(.18),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "-${t.discountApplied}%",
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF00B894,
                                                          ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetCtx, null),
                        child: const Text("Отмена"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // не возвращаем null по ошибке
                          Navigator.pop(sheetCtx, selected);
                        },
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.white.withOpacity(
                            .12,
                          ),
                          disabledForegroundColor: Colors.white70,
                        ),
                        // блокируем кнопку, если не выбран тариф
                        child: Text(
                          selected == null
                              ? "Выбрать"
                              : "Выбрать • ${selected!.price} ₸",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Максимально допустимая длительность от старта с учётом:
  /// - лимита 12 часов
  /// - 24-часового rolling-окна
  /// - окна ночного тарифа (если isNightTariff = true): до 08:00
  Duration _maxDurationForStart(DateTime start, {required bool isNightTariff}) {
    final now = DateTime.now();

    // лимит 24-часового окна от "сейчас"
    final endWindow = now.add(_rollingWindow);
    final capByWindow = endWindow.isBefore(start)
        ? Duration.zero
        : endWindow.difference(start);

    // лимит 12 часов от старта
    const capBy12h = Duration(hours: _maxHours);

    // лимит ночного окна до 08:00 (если требуется)
    Duration? capByNight;
    if (isNightTariff) {
      // вычисляем ближайшую "границу 08:00", которая идёт после старта
      late DateTime nightEnd;
      if (start.hour >= 22) {
        // старт после 22:00 — ночь считается до 08:00 следующего дня
        final nextDay = start.add(const Duration(days: 1));
        nightEnd = DateTime(nextDay.year, nextDay.month, nextDay.day, 8, 0);
      } else if (start.hour < 8) {
        // старт до 08:00 — ночь до 08:00 сегодняшнего дня
        // nightEnd = DateTime(start.year, start.month, start.day, 8, 0);
      } else {
        // старт не в "ночном" диапазоне: формально окно = 0
        nightEnd =
            start; // запретим выбирать что-то не в ночь (дальше проверим выше)
      }
      capByNight = nightEnd.isAfter(start)
          ? nightEnd.difference(start)
          : Duration.zero;
    }

    // сводим все ограничения к минимуму
    Duration maxDur = capByWindow < capBy12h ? capByWindow : capBy12h;
    if (isNightTariff && capByNight != null) {
      maxDur = capByNight < maxDur ? capByNight : maxDur;
    }

    if (maxDur.isNegative) return Duration.zero;
    return maxDur;
  }

  // ---------- ACTIONS ----------

  Future<void> _bookComputer(Computer comp) async {
    final tariff = await _pickTariff(comp);
    if (tariff == null) return;

    final bool isFixedWindow =
        (tariff.startAt != null && tariff.startAt!.isNotEmpty) &&
        (tariff.endAt != null && tariff.endAt!.isNotEmpty);

    DateTime startLocal;
    Duration dur;

    if (isFixedWindow) {
      final win = _computeNextFixedWindow(tariff.startAt, tariff.endAt);
      if (win == null) {
        AppSnack.show(
          context,
          message: "Неверные startAt/endAt у тарифа.",
          type: AppSnackType.error,
        );
        return;
      }

      final now = DateTime.now();
      // старт — либо сейчас (если уже идёт окно), либо начало окна
      startLocal = now.isBefore(win.startBoundary) ? win.startBoundary : now;

      // потолки конца:
      final byFixed = win.endBoundary;
      final by12h = startLocal.add(const Duration(hours: _maxHours));
      final by24h = DateTime.now().add(_rollingWindow);

      // реальный конец — минимум из трёх
      DateTime effectiveEnd = byFixed;
      if (by12h.isBefore(effectiveEnd)) effectiveEnd = by12h;
      if (by24h.isBefore(effectiveEnd)) effectiveEnd = by24h;

      // на случай, если ближайшее окно целиком за горизонтом 24ч
      if (!startLocal.isBefore(by24h)) {
        AppSnack.show(
          context,
          message: "Ближайшее окно фикс-тарифа выходит за 24 часа.",
          type: AppSnackType.error,
        );
        return;
      }

      dur = effectiveEnd.difference(startLocal);
      if (dur <= Duration.zero) {
        AppSnack.show(
          context,
          message: "Старт вне доступного окна. Выберите другой тариф/время.",
          type: AppSnackType.error,
        );
        return;
      }

      AppSnack.show(
        context,
        message:
            "Бронируем ПК #${comp.id} • «${tariff.title}» (${_hmPretty(tariff.startAt)}–${_hmPretty(tariff.endAt)})...",
        type: AppSnackType.info,
      );

      try {
        await api.booking(
          comp.id,
          'maintenance',
          startLocal,
          dur,
          tariffId:
              tariff.id, // обязательно передаём, чтобы сервер проверил окно
        );
        AppSnack.show(
          context,
          message: "ПК #${comp.id} забронирован!",
          type: AppSnackType.success,
        );
        _refresh();
      } catch (e) {
        final parsed = ServerError.parse(e);
        if (parsed.code == 'time_conflict') {
          _showConflictDialog(comp, parsed);
        } else if (parsed.code == 'out_of_window') {
          AppSnack.show(
            context,
            message:
                "Вне ближайших 24 часов. Доступное окно: ${parsed.windowReadable}",
            type: AppSnackType.error,
          );
        } else {
          AppSnack.show(
            context,
            message: parsed.message.isNotEmpty ? parsed.message : "Ошибка: $e",
            type: AppSnackType.error,
          );
        }
      }
      return;
    }
    // ---- НЕ фикс-окно: показываем picker времени ----
    final startUtc = await _pickStart(comp);
    if (startUtc == null) return;

    if (tariff.minutes > 0) {
      // фиксированная длительность по тарифу
      dur = Duration(minutes: tariff.minutes);
      startLocal = startUtc.toLocal();
    } else {
      // свободная длительность — показать ползунок
      final picked = await _pickDuration(startUtc, isNightTariff: false);
      if (picked == null) return;
      dur = picked;
      startLocal = startUtc.toLocal();
    }

    // стандартные проверки
    if (dur > const Duration(hours: _maxHours)) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: "Максимальная длительность — $_maxHours часов",
        type: AppSnackType.error,
      );
      return;
    }
    final latestEndAllowed = DateTime.now().add(_rollingWindow);
    if (startLocal.add(dur).isAfter(latestEndAllowed)) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message:
            "Бронь должна быть в пределах ближайших 24 часов (до ${formatDateTime(latestEndAllowed)}).",
        type: AppSnackType.error,
      );
      return;
    }

    if (!mounted) return;
    AppSnack.show(
      context,
      message: "Бронируем ПК #${comp.id} • «${tariff.title}»...",
      type: AppSnackType.info,
    );

    try {
      await api.booking(
        comp.id,
        'maintenance',
        startLocal,
        dur,
        tariffId: tariff.id, // <— тоже передаём (на будущее проверок)
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: "ПК #${comp.id} забронирован!",
        type: AppSnackType.success,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      final parsed = ServerError.parse(e);
      if (parsed.code == 'time_conflict') {
        _showConflictDialog(comp, parsed);
      } else if (parsed.code == 'out_of_window') {
        AppSnack.show(
          context,
          message:
              "Нельзя бронировать вне ближайших 24 часов. Доступное окно: ${parsed.windowReadable}",
          type: AppSnackType.error,
        );
      } else {
        AppSnack.show(
          context,
          message: parsed.message.isNotEmpty ? parsed.message : "Ошибка: $e",
          type: AppSnackType.error,
        );
      }
    }
  }

  Future<DateTime?> _pickStart(Computer comp) async {
    final List<TimeSlot> busy = await parseBookedComputer(comp);
    if (!mounted) return null;

    final DateTime? pickedStart = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: RealtimeClockBooking(
            busy: busy,
            minuteStep: const Duration(minutes: 15),
            clockSize: 250,
            maxStartAhead: const Duration(hours: 12), // <— ВАЖНО
            onConfirm: (startUtc) => Navigator.of(sheetCtx).pop(startUtc),
          ),
        );
      },
    );

    return pickedStart; // UTC
  }

  Future<Duration?> _pickDuration(
    DateTime start, {
    required bool isNightTariff,
  }) async {
    final maxDur = _maxDurationForStart(start, isNightTariff: isNightTariff);

    if (maxDur <= Duration.zero) {
      AppSnack.show(
        context,
        message: "Старт вне доступного окна. Выберите другое время.",
        type: AppSnackType.error,
      );
      return null;
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
                    "Максимум: ${readableDuration(maxDur)} (окно до ${formatDateTime(now.add(_rollingWindow))})",
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

  DateTime combineDayAndTime(DateTime day, TimeOfDay t) {
    return DateTime(day.year, day.month, day.day, t.hour, t.minute);
  }

  Future<List<TimeSlot>> parseBookedComputer(Computer comp) async {
    final bookingData = await api.fetchBookedIntervals(comp.id);
    final List<dynamic> booked = (bookingData['booked'] as List?) ?? const [];

    return booked.map((e) {
      final start = DateTime.parse(e['start'] as String);
      final end = DateTime.parse(e['end'] as String);
      return TimeSlot(start, end);
    }).toList();
  }

  void _unbookComputer(Computer comp) {
    AppSnack.show(
      context,
      message: "Отменяем бронь компьютера #${comp.id}...",
      type: AppSnackType.info,
    );
    api
        .booking(comp.id, "release", null, null)
        .then((_) {
          if (!mounted) return;
          AppSnack.show(
            context,
            message: "Бронь компьютера #${comp.id} отменена",
            type: AppSnackType.success,
          );
          _refresh();
        })
        .catchError((e) {
          if (!mounted) return;
          AppSnack.show(
            context,
            message: "Ошибка отмены: $e",
            type: AppSnackType.error,
          );
        });
  }

  // ---------- ERROR PARSING & CONFLICT DIALOG ----------

  void _showConflictDialog(Computer comp, ServerError err) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Конфликт по времени",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.message.isNotEmpty
                      ? err.message
                      : "Запрошенный интервал пересекается с существующей бронью.",
                  style: const TextStyle(color: Colors.white70),
                ),
                if (err.windowReadable.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Доступное окно: ${err.windowReadable}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 12),
                if (err.suggestions.isNotEmpty)
                  const Text(
                    "Предлагаем варианты:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (err.suggestions.isNotEmpty) const SizedBox(height: 8),
                if (err.suggestions.isNotEmpty)
                  ...err.suggestions
                      .take(3)
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _bookSuggested(comp, s);
                            },
                            child: Text(
                              "${formatDateTime(s.start)} • ${readableDuration(s.end.difference(s.start))}",
                            ),
                          ),
                        ),
                      ),
                if (err.suggestions.isEmpty)
                  const Text(
                    "Свободные варианты отсутствуют. Попробуйте выбрать другое время.",
                    style: TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Закрыть"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _bookSuggested(Computer comp, Suggestion s) async {
    AppSnack.show(
      context,
      message: "Пробуем вариант: ${formatDateTime(s.start)}...",
      type: AppSnackType.info,
    );
    try {
      await api.booking(
        comp.id,
        'maintenance',
        s.start,
        s.end.difference(s.start),
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: "Готово! ПК #${comp.id} забронирован.",
        type: AppSnackType.success,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: "Не удалось забронировать предложенный слот: $e",
        type: AppSnackType.error,
      );
    }
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QubeAppBar(
        icon: widget.isMapView ? Icons.map : Icons.computer,
        title: widget.isMapView ? "Карта клуба" : "Компьютеры",
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: widget.isMapView ? _buildMapView() : _buildListView(),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

// ---------------- FIXED-WINDOW HELPERS ----------------

TimeOfDay? _parseHm(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _hmPretty(String? s) => s ?? '';

DateTime _combine(DateTime base, TimeOfDay tod) =>
    DateTime(base.year, base.month, base.day, tod.hour, tod.minute);

class _FixedWindow {
  final DateTime startBoundary; // граница начала окна
  final DateTime endBoundary; // граница конца окна
  _FixedWindow(this.startBoundary, this.endBoundary);
}

/// Ближайшее окно по локальному времени клуба.
/// - Всегда возвращает ГРАНИЦЫ окна, без "start=now".
_FixedWindow? _computeNextFixedWindow(String? startAt, String? endAt) {
  final s = _parseHm(startAt);
  final e = _parseHm(endAt);
  if (s == null || e == null) return null;

  final now = DateTime.now();
  final todayStart = _combine(now, s);
  var todayEnd = _combine(now, e);

  final crossesMidnight =
      (e.hour < s.hour) || (e.hour == s.hour && e.minute <= s.minute);
  if (crossesMidnight && !todayEnd.isAfter(todayStart)) {
    todayEnd = todayEnd.add(const Duration(days: 1));
  }

  // Если мы ещё ДО старта окна → ближайшее окно сегодня
  if (now.isBefore(todayStart)) {
    return _FixedWindow(todayStart, todayEnd);
  }

  // Если мы ВНУТРИ окна → ближайшее окно сейчасшнее (границы: те же)
  if (now.isBefore(todayEnd)) {
    return _FixedWindow(todayStart, todayEnd);
  }

  // Окно прошло → завтра
  final tomorrow = now.add(const Duration(days: 1));
  final nextStart = _combine(tomorrow, s);
  var nextEnd = _combine(tomorrow, e);
  if (crossesMidnight && !nextEnd.isAfter(nextStart)) {
    nextEnd = nextEnd.add(const Duration(days: 1));
  }
  return _FixedWindow(nextStart, nextEnd);
}
