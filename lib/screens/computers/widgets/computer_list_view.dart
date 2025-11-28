import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/computers/widgets/computer_list_item.dart';
import 'package:qube/screens/computers/widgets/skeletons/list_skeleton.dart';
// import 'package:qube/widgets/list_skeleton.dart';

class ComputerListView extends StatelessWidget {
  final List<Computer> computers;
  final bool isLoading;
  final ScrollController scrollController;
  final Color Function(String) statusColor;
  final Function(BuildContext, Computer) onComputerTap;
  final Future<void> Function() onRefresh;
  final Set<int> animatedComputerIds;
  final bool shouldAnimateNewItems;

  const ComputerListView({
    super.key,
    required this.computers,
    required this.isLoading,
    required this.scrollController,
    required this.statusColor,
    required this.onComputerTap,
    required this.onRefresh,
    required this.animatedComputerIds,
    required this.shouldAnimateNewItems,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ListSkeleton();
    }

    if (computers.isEmpty) {
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
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: const Color(0xFF6C5CE7),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(
          bottom: kBottomNavigationBarHeight + 32,
          top: 8,
        ),
        itemCount: computers.length,
        itemBuilder: (context, index) {
          final comp = computers[index];
          final shouldAnimate =
              shouldAnimateNewItems && !animatedComputerIds.contains(comp.id);

          return ComputerListItem(
            key: ValueKey('comp_${comp.id}_$shouldAnimate'),
            comp: comp,
            statusColor: statusColor(comp.status),
            onTap: () => onComputerTap(context, comp),
            shouldAnimate: shouldAnimate,
            position: index,
          );
        },
      ),
    );
  }
}
