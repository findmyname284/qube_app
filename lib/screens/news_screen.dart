// lib/screens/news_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/helper.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isRefreshing = false;
  bool _isLoading = true;
  String _selectedFilter = 'Все';
  String _query = '';
  List<Promotion> promotions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await api.fetchPromotions();
      setStateSafe(() {
        promotions = list;
        _isLoading = false;
      });
    } catch (_) {
      // даже если ошибка — убираем лоадер, чтобы показать пустой стейт
      setStateSafe(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setStateSafe(() => _isRefreshing = true);
    await _load();
    setStateSafe(() => _isRefreshing = false);
  }

  List<Promotion> get _filtered {
    Iterable<Promotion> list = promotions;
    if (_selectedFilter != 'Все') {
      list = list.where((p) => (p.category ?? 'Акции') == _selectedFilter);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where(
        (p) =>
            p.title.toLowerCase().contains(q) ||
            (p.description).toLowerCase().contains(q),
      );
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: "Новости и акции",
        icon: Icons.newspaper_rounded,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // общий фон
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
          child: CustomScrollView(
            slivers: [
              // Параллакс-шапка
              SliverToBoxAdapter(
                child: _ParallaxHeader(
                  isRefreshing: _isRefreshing,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Актуальное",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SearchField(
                        hint: 'Поиск по новостям…',
                        onChanged: (v) => setStateSafe(() => _query = v),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'Все',
                              selected: _selectedFilter == 'Все',
                              onTap: () =>
                                  setStateSafe(() => _selectedFilter = 'Все'),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Акции',
                              selected: _selectedFilter == 'Акции',
                              onTap: () =>
                                  setStateSafe(() => _selectedFilter = 'Акции'),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Новости',
                              selected: _selectedFilter == 'Новости',
                              onTap: () => setStateSafe(
                                () => _selectedFilter = 'Новости',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Контент: лоадер / пусто / грид с карточками
              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => const _PromoSkeleton(),
                      childCount: 6,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.86,
                        ),
                  ),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    title: (_query.isNotEmpty || _selectedFilter != 'Все')
                        ? 'Ничего не найдено'
                        : 'Пока пусто',
                    subtitle: (_query.isNotEmpty || _selectedFilter != 'Все')
                        ? 'Попробуй изменить запрос или фильтры'
                        : 'Загляни позже — скоро будут анонсы!',
                    actionLabel: 'Сбросить',
                    onAction: (_query.isNotEmpty || _selectedFilter != 'Все')
                        ? () => setStateSafe(() {
                            _query = '';
                            _selectedFilter = 'Все';
                          })
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: kBottomNavigationBarHeight + 24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final promo = items[i];
                      return _FancyPromoCard(
                        promo: promo,
                        onTap: () => _openPromoDetails(context, promo),
                        indexSeed: i,
                      );
                    }, childCount: items.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.86,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ———————————————————————————————
/// Стильная карточка промо
/// ———————————————————————————————
class _FancyPromoCard extends StatelessWidget {
  final Promotion promo;
  final VoidCallback onTap;
  final int indexSeed;

  const _FancyPromoCard({
    required this.promo,
    required this.onTap,
    required this.indexSeed,
  });

  List<Color> _autoGradient(int seed) {
    // fallback-градиент, если в модели нет gradient
    const presets = [
      [Color(0xFF6C5CE7), Color(0xFFA363D9)],
      [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
      [Color(0xFF18DCFF), Color(0xFF7D5FFF)],
      [Color(0xFF00B894), Color(0xFF00CEC9)],
    ];
    return presets[seed % presets.length];
  }

  @override
  Widget build(BuildContext context) {
    final grad = (promo.gradient?.cast<Color>() ?? _autoGradient(indexSeed));
    final hasImage = promo.imageUrl?.isNotEmpty == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // фоновая картинка (если есть)
            if (hasImage)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.25),
                    BlendMode.darken,
                  ),
                  child: Image.network(
                    promo.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

            // мягкая стеклянная подложка
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.24),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),

            // контент
            Padding(
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
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
          ],
        ),
      ),
    );
  }
}

/// ———————————————————————————————
/// Параллакс-Header + тонкая полоска прогресса
/// ———————————————————————————————
class _ParallaxHeader extends StatelessWidget {
  final Widget child;
  final bool isRefreshing;

  const _ParallaxHeader({required this.child, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // фон со стеклом
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withOpacity(0.22),
                      const Color(0xFF1E1F2E).withOpacity(0.30),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: child,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: isRefreshing ? 2.5 : 0,
            child: isRefreshing
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    minHeight: 2.5,
                    color: Colors.white,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// ———————————————————————————————
/// Поисковое поле в стиле стекла
/// ———————————————————————————————
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1),
        ),
      ),
    );
  }
}

/// ———————————————————————————————
/// Фильтр-чипы (анимированные пилюли)
/// ———————————————————————————————
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C5CE7)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C5CE7)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// ———————————————————————————————
/// Шимер-скелетон карточки
/// ———————————————————————————————
class _PromoSkeleton extends StatefulWidget {
  const _PromoSkeleton();

  @override
  State<_PromoSkeleton> createState() => _PromoSkeletonState();
}

class _PromoSkeletonState extends State<_PromoSkeleton>
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

/// ———————————————————————————————
/// Пустой стейт
/// ———————————————————————————————
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_satisfied_rounded,
              color: Colors.white38,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// ———————————————————————————————
/// Bottom Sheet с адаптивной высотой (твоя логика)
/// ———————————————————————————————
void _openPromoDetails(BuildContext context, Promotion promo) {
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

/// ———————————————————————————————
/// MeasureSize (как у тебя)
/// ———————————————————————————————
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

/// ———————————————————————————————
/// Инфо-пилюля
/// ———————————————————————————————
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
