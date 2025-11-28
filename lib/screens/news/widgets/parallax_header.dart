import 'package:flutter/material.dart';

class ParallaxHeader extends StatelessWidget {
  final Widget child;
  final bool isRefreshing;

  const ParallaxHeader({
    super.key,
    required this.child,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF1E1F2E)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: child,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: isRefreshing ? 2.5 : 0,
            child: isRefreshing
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    minHeight: 2.5,
                    color: Colors.white,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
