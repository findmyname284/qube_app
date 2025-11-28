import 'package:flutter/material.dart';

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: 8,
      itemBuilder: (_, _) => const ComputerCardSkeleton(),
    );
  }
}

class ComputerCardSkeleton extends StatelessWidget {
  const ComputerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skelLine(widthFactor: 0.6, height: 16),
                const SizedBox(height: 6),
                _skelLine(widthFactor: 0.4, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skelLine({required double widthFactor, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
} // TODO Implement this library.
