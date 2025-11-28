import 'package:flutter/material.dart';
import 'package:qube/screens/bookings/widgets/skeletons/booking_card_skeleton.dart';

class BookingListSkeleton extends StatelessWidget {
  const BookingListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (_, _) => const BookingCardSkeleton(),
    );
  }
}
