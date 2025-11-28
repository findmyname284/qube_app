// lib/screens/news_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/screens/news/dialogs/promo_details_sheet.dart';
import 'package:qube/screens/news/widgets/empty_state.dart';
import 'package:qube/screens/news/widgets/filter_pills.dart';
import 'package:qube/screens/news/widgets/parallax_header.dart';
import 'package:qube/screens/news/widgets/promo_cards/optimized_promo_card.dart';
import 'package:qube/screens/news/widgets/promo_cards/promo_skeleton.dart';
import 'package:qube/screens/news/widgets/search_field.dart';
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
    Future.delayed(const Duration(milliseconds: 100), _load);
  }

  Future<void> _load() async {
    try {
      final list = await api.fetchPromotions();
      setStateSafe(() {
        promotions = list;
        _isLoading = false;
      });
    } catch (_) {
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

  void _openPromoDetails(BuildContext context, Promotion promo) {
    showPromoDetailsSheet(context, promo);
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
              SliverToBoxAdapter(
                child: ParallaxHeader(
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
                      SearchField(
                        hint: 'Поиск по новостям…',
                        onChanged: (v) => setStateSafe(() => _query = v),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterPill(
                              label: 'Все',
                              selected: _selectedFilter == 'Все',
                              onTap: () =>
                                  setStateSafe(() => _selectedFilter = 'Все'),
                            ),
                            const SizedBox(width: 8),
                            FilterPill(
                              label: 'Акции',
                              selected: _selectedFilter == 'Акции',
                              onTap: () =>
                                  setStateSafe(() => _selectedFilter = 'Акции'),
                            ),
                            const SizedBox(width: 8),
                            FilterPill(
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

              if (_isLoading)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => const PromoSkeleton(),
                      childCount: 4,
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
                  child: EmptyState(
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
                      return OptimizedPromoCard(
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
