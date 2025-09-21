import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class ComputersScreen extends StatefulWidget {
  final List<Computer> computers;
  final Function(bool isMap)? onMapModeChanged;
  const ComputersScreen({
    super.key,
    required this.computers,
    this.onMapModeChanged,
  });

  @override
  State<ComputersScreen> createState() => _ComputersScreenState();
}

class _ComputersScreenState extends State<ComputersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool showList = true;
  final double cellSize = 75;
  late List<Computer> _computers;

  @override
  void initState() {
    super.initState();
    _computers = widget.computers;

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
  }

  Future<void> _refresh() async {
    try {
      final computers = await api.fetchComputers();
      if (mounted) {
        setState(() {
          _computers = computers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка при обновлении: $e")));
      }
    }
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: _computers.length,
          itemBuilder: (context, index) {
            final comp = _computers[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: _buildComputerCard(comp)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComputerCard(Computer comp) {
    final zone = comp.zone.toUpperCase();
    return Card(
      child: ListTile(
        onTap: () => _showComputerDetails(context, comp),
        leading: const Icon(Icons.desktop_windows),
        title: Text("Компьютер №${comp.id} ($zone)"),
        subtitle: Text(
          "Статус: ${comp.status == "free"
              ? "Свободен"
              : comp.status == "booked"
              ? "На вас забронирован"
              : "Занят"}",
        ),
        trailing: OutlinedButton.icon(
          onPressed: () => _showComputerDetails(context, comp),
          icon: const Icon(Icons.info_outline),
          label: const Text('Детали'),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_computers.isEmpty) {
      return const Center(child: Text("Нет компьютеров для отображения"));
    }

    final maxX = _computers.map((c) => c.x).reduce((a, b) => a > b ? a : b);
    final maxY = _computers.map((c) => c.y).reduce((a, b) => a > b ? a : b);

    final fieldWidth = (maxX + 3) * cellSize;
    final fieldHeight = (maxY + 3) * cellSize;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.5,
      maxScale: 2.5,
      child: SizedBox(
        width: fieldWidth,
        height: fieldHeight,
        child: Stack(children: _computers.map(_buildComputerMarker).toList()),
      ),
    );
  }

  Widget _buildComputerMarker(Computer comp) {
    return Positioned(
      left: comp.x * cellSize,
      top: comp.y * cellSize,
      child: GestureDetector(
        onTap: () => _showComputerDetails(context, comp),
        child: Container(
          width: cellSize - 20,
          height: cellSize - 20,
          decoration: BoxDecoration(
            color: comp.status == "free"
                ? Colors.green
                : comp.status == "booked"
                ? Colors.amber
                : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.computer, size: 30),
              Text("PC ${comp.id}", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showComputerDetails(BuildContext context, Computer comp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      transitionAnimationController: _sheetController,
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
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: Text("Ошибка загрузки: ${snapshot.error}"),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 250,
                    child: Center(child: Text("Нет данных")),
                  );
                }

                final compDetail = snapshot.data!;

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
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.05),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              "Компьютер #${compDetail.id}",
                              key: ValueKey(compDetail.id),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
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
                            color: compDetail.status == "free"
                                ? Colors.green
                                : compDetail.status == "booked"
                                ? Colors.amber
                                : Colors.red,
                          ),
                          if (compDetail.zone.isNotEmpty)
                            _buildDetailRow(
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (compDetail.cpu != null &&
                              compDetail.cpu!.isNotEmpty)
                            _buildDetailRow(
                              "Процессор",
                              compDetail.cpu!,
                              image: "assets/icons/cpu.png",
                            ),
                          if (compDetail.gpu != null &&
                              compDetail.gpu!.isNotEmpty)
                            _buildDetailRow(
                              "Видеокарта",
                              compDetail.gpu!,
                              image: "assets/icons/gpu.png",
                            ),
                          if (compDetail.ram != null &&
                              compDetail.ram!.isNotEmpty)
                            _buildDetailRow(
                              "Оперативная память",
                              compDetail.ram!,
                              image: "assets/icons/ram.png",
                            ),
                          if (compDetail.monitor != null &&
                              compDetail.monitor!.isNotEmpty)
                            _buildDetailRow(
                              "Монитор",
                              compDetail.monitor!,
                              icon: Icons.desktop_windows,
                            ),
                          if (compDetail.keyboard != null &&
                              compDetail.keyboard!.isNotEmpty)
                            _buildDetailRow(
                              "Клавиатура",
                              compDetail.keyboard!,
                              icon: Icons.keyboard,
                            ),
                          if (compDetail.mouse != null &&
                              compDetail.mouse!.isNotEmpty)
                            _buildDetailRow(
                              "Мышь",
                              compDetail.mouse!,
                              icon: Icons.mouse,
                            ),
                          if (compDetail.headphones != null &&
                              compDetail.headphones!.isNotEmpty)
                            _buildDetailRow(
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

  Widget _buildDetailRow(
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
              child: Icon(icon, size: 24, color: color),
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
                  style: TextStyle(fontWeight: FontWeight.w500, color: color),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bookComputer(Computer comp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Бронируем компьютер #${comp.id}...")),
    );
    api
        .booking(comp.id, "maintenance")
        .then((booking) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Компьютер #${comp.id} забронирован!")),
            );
            _refresh();
          }
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка бронирования: $e")));
        });
  }

  void _unbookComputer(Computer comp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Отменяем бронь компьютера #${comp.id}...")),
    );
    api
        .booking(comp.id, "release")
        .then((booking) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Бронь компьютера #${comp.id} отменена!")),
            );
            _refresh();
          }
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Ошибка отмены: $e")));
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_computers.isEmpty) {
      return Scaffold(
        appBar: QubeAppBar(
          title: "Компьютеры",
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
        ),
        body: const Center(
          child: Text(
            "Нет данных о компьютерах",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    void toggleView() {
      setState(() {
        showList = !showList;
      });
      widget.onMapModeChanged?.call(!showList);
    }

    return Scaffold(
      appBar: QubeAppBar(
        title: showList ? "Компьютеры" : "Карта клуба",
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: showList ? _buildListView() : _buildMapView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleView,
        child: Icon(showList ? Icons.map : Icons.list),
      ),
    );
  }
}
