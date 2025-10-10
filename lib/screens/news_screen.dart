// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/helper.dart';
import 'package:qube/widgets/promotion_card.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isRefreshing = false;
  String _selectedFilter = 'Все';
  List<Promotion> promotions = [];

  // демо-данные
  //   late List<Promotion> promotions = [
  //     Promotion(
  //       title: "4+3 Абонемент + Energy",
  //       description: "Купи тариф 4+3 и получи 1 Tassay Energy бесплатно!",
  //       imageUrl: "https://imageproxy.wolt.com/assets/685ed326f43200b6b5209f2a",
  //       gradient: const [Color(0xFF6C5CE7), Color(0xFFA363D9)],
  //       icon: Icons.local_offer_rounded,
  //       category: 'Акции',
  //     ),
  //     Promotion(
  //       title: "Конкурс пополнений",
  //       description:
  //           "Пополни аккаунт на 5000₸ и участвуй в розыгрыше:\n"
  //           "• 🎧 Marshall накладные\n"
  //           "• 🎶 Marshall как AirPods\n"
  //           "• 🖱️ VGN Dragonfly",
  //       imageUrl:
  //           "https://pspdf.kz/image/catalog/products/zvuk/marshall-motif-ii/1.jpg",
  //       endDate: DateTime(2025, 10, 31),
  //       gradient: const [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFF5F2C82)],
  //       icon: Icons.celebration_rounded,
  //       category: 'Акции',
  //     ),
  //     Promotion(
  //       title: "Ночной тариф",
  //       description: "С 00:00 до 08:00 специальные цены для ночных геймеров!",
  //       gradient: const [Color(0xFF18DCFF), Color(0xFF7D5FFF)],
  //       icon: Icons.nightlife_rounded,
  //       category: 'Новости',
  //     ),
  //   ];
  @override
  void initState() {
    super.initState();
    api.fetchPromotions().then((value) {
      setStateSafe(() {
        promotions = value;
      });
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setStateSafe(() => _isRefreshing = true);

    // имитация обновления (подключи API — и просто обнови promotions)
    await Future.delayed(const Duration(milliseconds: 700));

    setStateSafe(() => _isRefreshing = false);
  }

  List<Promotion> get _filtered {
    if (_selectedFilter == 'Все') return promotions;
    return promotions
        .where((p) => (p.category ?? 'Акции') == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: "Новости и акции",
        icon: Icons.newspaper_rounded,
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(2.5),
        //   child: AnimatedContainer(
        //     duration: const Duration(milliseconds: 250),
        //     height: _isRefreshing ? 2.5 : 0,
        //     child: _isRefreshing
        //         ? const LinearProgressIndicator(
        //             backgroundColor: Colors.transparent,
        //             minHeight: 2.5,
        //           )
        //         : const SizedBox.shrink(),
        //   ),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // фон в стиле остальных экранов
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: Colors.white,
          backgroundColor: const Color(0xFF6C5CE7),
          child: ListView(
            padding: EdgeInsets.only(
              bottom: kBottomNavigationBarHeight + 24,
              top: 12,
              left: 16,
              right: 16,
            ),
            children: [
              // шапка секции + фильтры
              Row(
                children: [
                  const Text(
                    "Актуальное",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _FilterChip(
                    label: 'Все',
                    selected: _selectedFilter == 'Все',
                    onTap: () => setStateSafe(() => _selectedFilter = 'Все'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Акции',
                    selected: _selectedFilter == 'Акции',
                    onTap: () => setStateSafe(() => _selectedFilter = 'Акции'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Новости',
                    selected: _selectedFilter == 'Новости',
                    onTap: () =>
                        setStateSafe(() => _selectedFilter = 'Новости'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // список карточек
              ...List.generate(_filtered.length, (index) {
                final promo = _filtered[index];
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 250 + index * 70),
                    tween: Tween(begin: 0.96, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: PromotionCard(
                      promo: promo,
                      onMore: () => _openPromoDetails(context, promo),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

void _openPromoDetails(BuildContext context, Promotion promo) {
  const double kMinGlobal = 0.25; // минимум 25%
  const double kMaxGlobal = 0.90; // глобальный потолок
  const double kHeadroom = 0.05; // +5% запаса над контентом

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
      // локальные параметры, которые будем обновлять после измерения
      double minSize = kMinGlobal;
      double targetSize = 0.5; // стартовая догадка
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
                    // фактическая высота контента (плюс небольшой запас)
                    final contentH = size.height + 28;
                    final contentRatio = (contentH / screenH).clamp(
                      kMinGlobal,
                      kMaxGlobal,
                    );

                    final newTarget = contentRatio; // открыть "по контенту"
                    final newMax = (newTarget + kHeadroom).clamp(
                      newTarget,
                      kMaxGlobal,
                    ); // контент+запас, но <= 90%

                    // обновляем только при заметном отличии, чтобы избежать зацикливания
                    final changed =
                        (newTarget - targetSize).abs() > 0.01 ||
                        (newMax - maxSize).abs() > 0.01;

                    if (changed) {
                      setSheetState(() {
                        targetSize = newTarget;
                        maxSize = newMax;
                        // min фиксированный (25%)
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // заголовок
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
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
                                    color: Colors.white.withValues(alpha: 0.06),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.06),
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
                            const SizedBox(width: 12),
                            // Expanded(
                            //   child: ElevatedButton.icon(
                            //     onPressed: () {
                            //       /* действие */
                            //     },
                            //     icon: const Icon(Icons.local_activity_rounded),
                            //     label: const Text("Участвовать"),
                            //   ),
                            // ),
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

class RenderMeasureSize extends RenderProxyBox {
  RenderMeasureSize(this.onChange);
  ValueChanged<Size> onChange;
  Size? _old;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_old == newSize) return;
    _old = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;
  const MeasureSize({super.key, required this.onChange, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C5CE7)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C5CE7)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
