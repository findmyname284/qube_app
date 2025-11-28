import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';

class ComputerDetailsSheet extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Computer computer;
  final Color statusColor;
  final VoidCallback onBook;
  final VoidCallback onUnbook;

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: const Text(
                  "Детали компьютера",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23243A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Компьютер #${computer.id}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Зона: ${computer.zone}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Статус: ${_getStatusText(computer.status)}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onUnbook();
                        },
                        child: const Text("Отменить бронь"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onBook();
                        },
                        child: const Text("Забронировать"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case "free":
        return "Свободен";
      case "booked":
        return "Забронирован";
      case "busy":
        return "Занят";
      default:
        return status;
    }
  }
}
