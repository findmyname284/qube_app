import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/computers/widgets/computer_marker.dart';

class ComputerMapView extends StatelessWidget {
  final List<Computer> computers;
  final bool isLoading;
  final double cellSize;
  final Color Function(String) statusColor;
  final Function(BuildContext, Computer) onComputerTap;
  final Widget topProgress;

  const ComputerMapView({
    super.key,
    required this.computers,
    required this.isLoading,
    required this.cellSize,
    required this.statusColor,
    required this.onComputerTap,
    required this.topProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    if (computers.isEmpty) {
      return const Center(
        child: Text(
          "Нет компьютеров для отображения",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final maxX = computers
        .map((c) => c.x.toDouble())
        .fold<double>(0.0, (prev, v) => max(prev, v));
    final maxY = computers
        .map((c) => c.y.toDouble())
        .fold<double>(0.0, (prev, v) => max(prev, v));
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
                children: computers
                    .map(
                      (c) => ComputerMarker(
                        key: ValueKey('marker_${c.id}'),
                        comp: c,
                        cellSize: cellSize,
                        color: statusColor(c.status),
                        onTap: () => onComputerTap(context, c),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: topProgress),
      ],
    );
  }
}
