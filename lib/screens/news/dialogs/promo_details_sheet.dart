import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/screens/news/utils/measure_size.dart';

void showPromoDetailsSheet(BuildContext context, Promotion promo) {
  const double kMinGlobal = 0.25;
  const double kMaxGlobal = 0.90;
  const double kHeadroom = 0.05;

  final dragCtrl = DraggableScrollableController();

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E1F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      double minSize = kMinGlobal;
      double targetSize = 0.5;
      double maxSize = (targetSize + kHeadroom).clamp(targetSize, kMaxGlobal);

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            controller: dragCtrl,
            expand: false,
            snap: true,
            snapSizes: [minSize, targetSize, maxSize],
            initialChildSize: targetSize,
            minChildSize: minSize,
            maxChildSize: maxSize,
            builder: (context, scrollController) {
              final screenH = MediaQuery.of(context).size.height;

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: MeasureSize(
                  onChange: (size) {
                    final contentH = size.height + 28;
                    final contentRatio = (contentH / screenH).clamp(
                      kMinGlobal,
                      kMaxGlobal,
                    );

                    final newTarget = contentRatio;
                    final newMax = (newTarget + kHeadroom).clamp(
                      newTarget,
                      kMaxGlobal,
                    );

                    final changed =
                        (newTarget - targetSize).abs() > 0.01 ||
                        (newMax - maxSize).abs() > 0.01;

                    if (changed) {
                      setSheetState(() {
                        targetSize = newTarget;
                        maxSize = newMax;
                      });

                      if (dragCtrl.isAttached) {
                        dragCtrl.animateTo(
                          targetSize,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    }
                  },
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                promo.icon ?? Icons.campaign_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                promo.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (promo.imageUrl?.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                promo.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, ev) {
                                  if (ev == null) return child;
                                  return Container(
                                    color: Colors.white.withOpacity(0.06),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white.withOpacity(0.06),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        Text(
                          promo.description,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (promo.endDate != null)
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            text:
                                "Действует до ${promo.endDate!.day}.${promo.endDate!.month}.${promo.endDate!.year}",
                          ),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Закрыть"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
