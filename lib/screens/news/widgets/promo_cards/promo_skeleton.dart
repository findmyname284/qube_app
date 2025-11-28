import 'package:flutter/material.dart';

class PromoSkeleton extends StatefulWidget {
  const PromoSkeleton({super.key});

  @override
  State<PromoSkeleton> createState() => _PromoSkeletonState();
}

class _PromoSkeletonState extends State<PromoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final t = (0.6 + 0.4 * c.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.04 * t),
                Colors.white.withOpacity(0.08 * t),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08 * t),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12 * t),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08 * t),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const Spacer(),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10 * t),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
