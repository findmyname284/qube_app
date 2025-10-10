import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';

class ComputerMarker extends StatelessWidget {
  final Computer comp;
  final double cellSize;
  final Color color;
  final VoidCallback onTap;

  const ComputerMarker({
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
                color: color.withValues(alpha: 0.35),
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
