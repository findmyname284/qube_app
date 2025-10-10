import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/services/api_service.dart';

final api = ApiService.instance;

class ComputerDetailsSheet extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Computer computer;
  final Color statusColor;
  final Function(Computer) onBook;
  final Function(Computer) onUnbook;

  const ComputerDetailsSheet({
    super.key,
    required this.fade,
    required this.slide,
    required this.computer,
    required this.statusColor,
    required this.onBook,
    required this.onUnbook,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: FutureBuilder<Computer>(
          future: api.fetchComputer(computer.id),
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
                                  onBook(compDetail);
                                },
                                child: const Text("Забронировать"),
                              ),
                            ),
                          if (compDetail.status == "booked")
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onUnbook(compDetail);
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
  }

  Color _statusColor(String s) => s == "free"
      ? const Color(0xFF00B894)
      : s == "booked"
      ? const Color(0xFFFFC048)
      : const Color(0xFFFF7676);

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
}
