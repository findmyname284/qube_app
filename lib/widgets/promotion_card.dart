import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';

class PromotionCard extends StatelessWidget {
  final Promotion promo;

  const PromotionCard({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    final isBanner = promo.imageUrl != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBanner)
            Image.network(
              promo.imageUrl!,
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            )
          else
            ListTile(
              leading: const Icon(Icons.campaign, color: Colors.blue),
              title: Text(
                promo.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(promo.description),
            ),
          if (isBanner)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          if (promo.endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                "Действует до ${promo.endDate!.day}.${promo.endDate!.month}.${promo.endDate!.year}",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          if (promo.endDate == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                "Акция без срока",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
