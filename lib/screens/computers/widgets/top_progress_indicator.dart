import 'package:flutter/material.dart';

class TopProgressIndicator extends StatelessWidget {
  final bool isRefreshing;

  const TopProgressIndicator({super.key, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: isRefreshing ? 2.5 : 0,
      child: isRefreshing
          ? const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              minHeight: 2.5,
            )
          : const SizedBox.shrink(),
    );
  }
}
