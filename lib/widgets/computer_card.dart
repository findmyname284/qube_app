import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';

class ComputerCard extends StatelessWidget {
  final Computer comp;
  final VoidCallback onTap;
  final Color statusColor;

  const ComputerCard({
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
            color: const Color(0xFF1E1F2E).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
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
