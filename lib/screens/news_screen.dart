import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/widgets/promotion_card.dart';
import 'package:qube/widgets/qubebar.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promotions = [
      Promotion(
        title: "4+3 Абонемент + Energy",
        description: "Купи тариф 4+3 и получи 1 Tassay Energy бесплатно!",
        imageUrl: "https://imageproxy.wolt.com/assets/685ed326f43200b6b5209f2a",
        endDate: DateTime(2025, 9, 20),
      ),
      Promotion(
        title: "Конкурс пополнений",
        description:
            "Пополни аккаунт на 5000₸ и участвуй в розыгрыше:\n"
            "- 🎧 Marshall накладные\n"
            "- 🎶 Marshall как AirPods\n"
            "- 🖱️ Vgn dragonfly мышка",
        imageUrl:
            "https://pspdf.kz/image/catalog/products/zvuk/marshall-motif-ii/1.jpg",
        endDate: DateTime(2025, 10, 31),
      ),
    ];

    return Scaffold(
      appBar: QubeAppBar(title: "Новости"),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promo = promotions[index];
          return PromotionCard(promo: promo);
        },
      ),
    );
  }
}
