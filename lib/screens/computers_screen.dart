import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';

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
      setState(() {
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
    super.dispose();
  }

  // ---------- DATA LOADING ----------

  Future<void> _refreshInitial() async {
    setState(() => isLoading = true);
    try {
      final list = await api.fetchComputers();
      if (!mounted) return;
      setState(() => _computers = list);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    setState(() => isRefreshing = true);
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
      if (mounted) setState(() => isRefreshing = false);
    }
  }

  // Мягкое применение обновлений (без «мигания» списка)
  void _applyDiffUpdate(List<Computer> fresh) {
    // Сортируем по id, чтобы порядок был стабильным, иначе лишние анимации
    fresh.sort((a, b) => a.id.compareTo(b.id));

    // Обновляем только если реально что-то поменялось
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
      setState(() => _computers = fresh);
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
      return _ListSkeleton();
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
          padding: EdgeInsets.only(
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
                  child: _ComputerCard(
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
                      (c) => _AnimatedMarker(
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
        // тонкая полоска прогресса сверху
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
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: FutureBuilder<Computer>(
              future: api.fetchComputer(comp.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: Text(
                        "Ошибка загрузки: ${snapshot.error}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: Text(
                        "Нет данных",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                final compDetail = snapshot.data!;
                final color = _statusColor(compDetail.status);

                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.78,
                  minChildSize: 0.4,
                  maxChildSize: 0.8,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              "Компьютер #${compDetail.id}",
                              key: ValueKey("title-${compDetail.id}"),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _detailRow(
                            "Статус",
                            compDetail.status == "free"
                                ? "Свободен"
                                : compDetail.status == "booked"
                                ? "На вас забронирован"
                                : "Занят",
                            icon: compDetail.status == "free"
                                ? Icons.check_circle
                                : compDetail.status == "booked"
                                ? Icons.hourglass_empty
                                : Icons.block,
                            color: color,
                          ),
                          if (compDetail.zone.isNotEmpty)
                            _detailRow(
                              "Зона",
                              compDetail.zone.toUpperCase(),
                              icon: Icons.location_on,
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            "Характеристики:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (compDetail.cpu?.isNotEmpty == true)
                            _detailRow(
                              "Процессор",
                              compDetail.cpu!,
                              image: "assets/icons/cpu.png",
                            ),
                          if (compDetail.gpu?.isNotEmpty == true)
                            _detailRow(
                              "Видеокарта",
                              compDetail.gpu!,
                              image: "assets/icons/gpu.png",
                            ),
                          if (compDetail.ram?.isNotEmpty == true)
                            _detailRow(
                              "Оперативная память",
                              compDetail.ram!,
                              image: "assets/icons/ram.png",
                            ),
                          if (compDetail.monitor?.isNotEmpty == true)
                            _detailRow(
                              "Монитор",
                              compDetail.monitor!,
                              icon: Icons.desktop_windows,
                            ),
                          if (compDetail.keyboard?.isNotEmpty == true)
                            _detailRow(
                              "Клавиатура",
                              compDetail.keyboard!,
                              icon: Icons.keyboard,
                            ),
                          if (compDetail.mouse?.isNotEmpty == true)
                            _detailRow(
                              "Мышь",
                              compDetail.mouse!,
                              icon: Icons.mouse,
                            ),
                          if (compDetail.headphones?.isNotEmpty == true)
                            _detailRow(
                              "Наушники",
                              compDetail.headphones!,
                              icon: Icons.headset,
                            ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Закрыть"),
                                ),
                              ),
                              if (compDetail.status == "free")
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _bookComputer(compDetail);
                                    },
                                    child: const Text("Забронировать"),
                                  ),
                                ),
                              if (compDetail.status == "booked")
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _unbookComputer(compDetail);
                                    },
                                    child: const Text("Отменить бронь"),
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
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    IconData? icon,
    String? image,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: 24, color: color ?? Colors.white70),
            ),
          if (icon == null && image != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.asset(image, height: 24),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.white70,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    value,
                    key: ValueKey("$title-$value"),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ACTIONS ----------

  void _bookComputer(Computer comp) {
    AppSnack.show(
      context,
      message: "Бронируем компьютер #${comp.id}...",
      type: AppSnackType.info,
    );
    api
        .booking(comp.id, "maintenance")
        .then((_) {
          if (!mounted) return;
          AppSnack.show(
            context,
            message: "Компьютер #${comp.id} забронирован!",
            type: AppSnackType.success,
          );
          _refresh();
        })
        .catchError((e) {
          if (!mounted) return;
          AppSnack.show(
            context,
            message: "Ошибка бронирования: $e",
            type: AppSnackType.error,
          );
        });
  }

  void _unbookComputer(Computer comp) {
    AppSnack.show(
      context,
      message: "Отменяем бронь компьютера #${comp.id}...",
      type: AppSnackType.info,
    );
    api
        .booking(comp.id, "release")
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
          // фон в стиле профиля
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

// ========= WIDGETS =========

class _ComputerCard extends StatelessWidget {
  final Computer comp;
  final VoidCallback onTap;
  final Color statusColor;

  const _ComputerCard({
    super.key,
    required this.comp,
    required this.onTap,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F2E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // статус-иконка с плавной сменой цвета
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(begin: statusColor, end: statusColor),
                duration: const Duration(milliseconds: 250),
                builder: (_, c, __) => Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (c ?? statusColor).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.desktop_windows, color: c ?? statusColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        "Компьютер №${comp.id} (${comp.zone.toUpperCase()})",
                        key: ValueKey("title-${comp.id}-${comp.zone}"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        "Статус: ${comp.status == "free"
                            ? "Свободен"
                            : comp.status == "booked"
                            ? "На вас забронирован"
                            : "Занят"}",
                        key: ValueKey("status-${comp.id}-${comp.status}"),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

// Скелетоны, как в профиле
class _ListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: 8,
      itemBuilder: (_, __) => const _ComputerCardSkeleton(),
    );
  }
}

class _ComputerCardSkeleton extends StatelessWidget {
  const _ComputerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skelLine(widthFactor: 0.6, height: 16),
                const SizedBox(height: 6),
                _skelLine(widthFactor: 0.4, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skelLine({required double widthFactor, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Маркер на карте с плавными изменениями
class _AnimatedMarker extends StatelessWidget {
  final Computer comp;
  final double cellSize;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedMarker({
    super.key,
    required this.comp,
    required this.cellSize,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: comp.x * cellSize,
      top: comp.y * cellSize,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: cellSize - 20,
          height: cellSize - 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.computer, size: 26, color: Colors.black87),
              Text(
                "PC ${comp.id}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
