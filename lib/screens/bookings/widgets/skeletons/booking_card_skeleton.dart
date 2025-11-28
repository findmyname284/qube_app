import 'package:flutter/material.dart';

class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _skelLine(0.7, 16),
                const SizedBox(height: 8),
                _skelLine(0.4, 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _skelPill(56, 24),
        ],
      ),
    );
  }

  Widget _skelLine(double widthFactor, double height) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  Widget _skelPill(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
    ),
  );
}
