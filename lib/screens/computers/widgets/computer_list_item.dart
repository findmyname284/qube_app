import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/computers/widgets/computer_card.dart';

class ComputerListItem extends StatelessWidget {
  final Computer comp;
  final Color statusColor;
  final VoidCallback onTap;
  final bool shouldAnimate;
  final int position;

  const ComputerListItem({
    super.key,
    required this.comp,
    required this.statusColor,
    required this.onTap,
    required this.shouldAnimate,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final content = ComputerCard(
      key: ValueKey(comp.id),
      comp: comp,
      onTap: onTap,
      statusColor: statusColor,
    );

    if (!shouldAnimate) {
      return RepaintBoundary(child: content);
    }

    return AnimationConfiguration.staggeredList(
      position: position,
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        verticalOffset: 28.0,
        child: FadeInAnimation(child: RepaintBoundary(child: content)),
      ),
    );
  }
}
