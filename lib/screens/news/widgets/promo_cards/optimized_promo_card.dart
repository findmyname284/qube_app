import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/screens/news/utils/promo_helpers.dart';

class OptimizedPromoCard extends StatelessWidget {
  final Promotion promo;
  final VoidCallback onTap;
  final int indexSeed;

  const OptimizedPromoCard({
    super.key,
    required this.promo,
    required this.onTap,
    required this.indexSeed,
  });

  @override
  Widget build(BuildContext context) {
    final grad = (promo.gradient?.cast<Color>() ?? autoGradient(indexSeed));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grad,
          ),
          boxShadow: [
            BoxShadow(
              color: grad.last.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // шапка: иконка + бейдж категории/даты
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      promo.icon ?? Icons.campaign_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (promo.endDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        "до ${promo.endDate!.day}.${promo.endDate!.month}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // заголовок
              Text(
                promo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              // описание-тизер
              Text(
                promo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              // кнопка "Подробнее"
              Row(
                children: [
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Подробнее",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
