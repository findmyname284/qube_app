import 'package:flutter/material.dart';
import 'package:qube/screens/profile/widgets/skeletons/discount_skeleton.dart';

class DiscountCard extends StatelessWidget {
  const DiscountCard({
    super.key,
    required this.discount,
    required this.discountLoading,
    required this.isLoggedIn,
  });

  final double? discount;
  final bool discountLoading;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return const SizedBox.shrink();
    if (discountLoading) return DiscountSkeleton();
    if (discount == null || discount! <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F43).withOpacity(.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ваша скидка',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'Действует на все тарифы',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${discount!.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
