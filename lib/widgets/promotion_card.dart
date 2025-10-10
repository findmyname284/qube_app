// lib/widgets/promotion_card.dart
import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/utils/helper.dart';

class PromotionCard extends StatefulWidget {
  final Promotion promo;
  final VoidCallback? onMore;

  const PromotionCard({super.key, required this.promo, this.onMore});

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard> {
  ImageProvider? _imageProvider;
  bool _postFramePassed = false;

  @override
  void initState() {
    super.initState();
    // Ждём первый кадр, чтобы не мешать анимации навигации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setStateSafe(() => _postFramePassed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final hasImage = promo.imageUrl != null && promo.imageUrl!.isNotEmpty;
    final gradientColors =
        promo.gradient ?? const [Color(0xFF6C5CE7), Color(0xFFA363D9)];
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onMore,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // лениво готовим ресайз-провайдер и кэшируем после первого кадра
            if (_imageProvider == null && _postFramePassed && hasImage) {
              final cacheW = (constraints.maxWidth * dpr)
                  .clamp(1, 100000)
                  .toInt();
              const logicalH = 180.0;
              final cacheH = (logicalH * dpr).clamp(1, 100000).toInt();

              final provider = ResizeImage(
                NetworkImage(promo.imageUrl!),
                width: cacheW,
                height: cacheH,
              );

              precacheImage(provider, context).then((_) {
                setStateSafe(() => _imageProvider = provider);
              });
            }

            return Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                // image: _imageProvider != null
                //     ? DecorationImage(image: _imageProvider!, fit: BoxFit.cover)
                //     : null,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (_imageProvider != null)
                    ? Colors.black.withValues(alpha: 0.22)
                    : null,
              ),
              child: Stack(
                children: [
                  // сияющий кружок как в других экранах
                  Positioned(
                    top: -18,
                    right: -18,
                    child: IgnorePointer(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // контент
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // иконка + заголовок
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Icon(
                                promo.icon ?? Icons.campaign_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                promo.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // описание
                        Expanded(
                          child: Text(
                            promo.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),

                        // нижняя линия: дата + «Подробнее»
                        Row(
                          children: [
                            if (promo.endDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "До ${promo.endDate!.day}.${promo.endDate!.month}.${promo.endDate!.year}",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: widget.onMore,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.chevron_right, size: 18),
                              label: const Text(
                                "Подробнее",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
