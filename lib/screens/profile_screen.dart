import 'package:flutter/material.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/tariff.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';
import 'package:qube/widgets/zone_chips.dart';

/// NOTE: визуально богаче, но без тяжёлых эффектов (никаких blur/BackDropFilter)
/// Оптимизации:
/// - Много где const
/// - Slivers вместо SingleChildScrollView
/// - RepaintBoundary для тяжёлых секций
/// - Отдельные Stateless виджеты для карточек (меньше перерисовок)
/// - Мягкие анимации через AnimatedSwitcher/AnimatedOpacity (дешёвые)
/// - Без ненужных setState; аккуратная перезагрузка данных

final api = ApiService.instance;

class ProfileScreen extends StatefulWidget {
  final List<Tariff>? tariffs; // можно передать снаружи
  final Profile? profile; // можно передать снаружи
  final void Function(Profile)? onLoggedIn;
  final void Function()? onLoggedOut;

  const ProfileScreen({
    super.key,
    this.tariffs,
    this.profile,
    this.onLoggedIn,
    this.onLoggedOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  // --- профиль ---
  bool isLoading = true; // загрузка профиля
  bool isLoggedIn = false;
  Profile? profile;
  bool _showBalance = true;

  // --- тарифы ---
  List<Tariff> _tariffs = const [];
  bool _tariffsLoading = false;

  // зоны (если не пришли тарифы — подгрузим динамически)
  List<String> _zones = const [];
  String _selectedZone = 'main';

  @override
  void initState() {
    super.initState();

    // стартовые данные по тарифам, если пришли сверху
    if (widget.tariffs != null && widget.tariffs!.isNotEmpty) {
      _tariffs = widget.tariffs!;
      final fromTariffs = widget.tariffs!
          .expand((t) => t.zonePrices.keys)
          .map((e) => e.toString())
          .toSet();
      if (fromTariffs.isNotEmpty) {
        _zones = fromTariffs.toList()..sort();
        if (!_zones.contains(_selectedZone)) {
          _selectedZone = _zones.first;
        }
      }
    } else {
      _loadTariffsForZone(_selectedZone);
    }

    // профиль: если передали — показываем сразу + мягкий фон-рефреш
    if (widget.profile != null) {
      isLoggedIn = true;
      profile = widget.profile;
      isLoading = false;
      _softRefreshInBackground();
    } else {
      Future.microtask(_loadProfile);
    }
  }

  // ---------- API: Профиль ----------

  Future<void> _softRefreshInBackground() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;
      final fresh = await api.getProfile();
      if (fresh == null) return;
      if (!mounted) return;
      setState(() {
        isLoggedIn = true;
        profile = fresh;
      });
      widget.onLoggedIn?.call(fresh);
    } catch (_) {
      /* тихо */
    }
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      if (token != null) {
        final fetched = await api.getProfile();
        if (!mounted) return;
        setState(() {
          isLoggedIn = fetched != null;
          profile = fetched;
        });
        if (fetched != null) widget.onLoggedIn?.call(fetched);
      } else {
        if (!mounted) return;
        setState(() {
          isLoggedIn = false;
          profile = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoggedIn = false;
        profile = null;
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------- API: Тарифы ----------

  Future<void> _loadTariffsForZone(String zone) async {
    setState(() {
      _tariffsLoading = true; // не очищаем, чтобы не мигало
    });
    try {
      final t = await api.fetchTariffs(zone: zone);
      if (!mounted) return;
      setState(() => _tariffs = t);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: 'Не удалось загрузить тарифы',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => _tariffsLoading = false);
    }
  }

  Future<void> _triggerRefresh() async {
    await Future.wait([_loadProfile(), _loadTariffsForZone(_selectedZone)]);
  }

  // ---------- Выход ----------

  Future<void> _logout() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutDialog(),
    );
    if (res != true) return;
    await AuthStorage.clearToken();
    if (!mounted) return;
    setState(() {
      isLoggedIn = false;
      profile = null;
    });
    widget.onLoggedOut?.call();
    AppSnack.show(
      context,
      message: 'Вы вышли из аккаунта',
      type: AppSnackType.success,
    );
  }

  void _toggleBalanceVisibility() {
    setState(() => _showBalance = !_showBalance);
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: 'Профиль',
        icon: Icons.person_rounded,
        actions: [
          if (isLoggedIn && !isLoading)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, size: 18),
              ),
              onPressed: _logout,
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
          key: _refreshKey,
          onRefresh: _triggerRefresh,
          backgroundColor: const Color(0xFF6C5CE7),
          color: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileHeader(
                      isLoading: isLoading,
                      isLoggedIn: isLoggedIn,
                      profile: profile,
                      showBalance: _showBalance,
                      onToggleBalance: _toggleBalanceVisibility,
                      onTopUp: isLoggedIn
                          ? _showTopUpSheet
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    if (!isLoading) _DiscountCard(profile: profile),
                    const SizedBox(height: 8),
                    if (!isLoading) _TariffsHeader(),
                    if (!isLoading)
                      ZoneChips(
                        zones: _zones,
                        selected: _selectedZone,
                        onChanged: (z) {
                          if (_selectedZone == z) return;
                          setState(() => _selectedZone = z);
                          _loadTariffsForZone(z);
                        },
                      ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),

              // Тарифы: отдельная секция с RepaintBoundary
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _TariffList(
                      loading: _tariffsLoading,
                      tariffs: _tariffs,
                      selectedZone: _selectedZone,
                      discount: (isLoggedIn ? (profile?.discount ?? 0) : 0),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _QuickActions(isLoading: isLoading),
                ),
              ),

              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTopUpSheet() async {
    if (!isLoggedIn) return;

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _TopUpSheet(
        onSubmit: (amount) async {
          final updated = await api.topUpBalance(amount);
          if (!mounted) return false;
          if (updated != null) {
            setState(() {
              profile = updated;
              isLoggedIn = true;
            });
            return true;
          }
          return false;
        },
      ),
    );

    if (result != null && mounted) {
      AppSnack.show(
        context,
        message: 'Баланс пополнен на $result ₸',
        type: AppSnackType.success,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}

// ===================== UI parts =====================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isLoading,
    required this.isLoggedIn,
    required this.profile,
    required this.showBalance,
    required this.onToggleBalance,
    this.onTopUp,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final Profile? profile;
  final bool showBalance;
  final VoidCallback onToggleBalance;
  final VoidCallback? onTopUp;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingHeader();

    final gradient = isLoggedIn
        ? const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF1E1F2E), Color(0xFF23233A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            spreadRadius: -4,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarBadge(isLoggedIn: isLoggedIn),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn
                          ? (profile?.username ?? 'Пользователь')
                          : 'Гость',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isLoggedIn
                          ? _Balance(
                              show: showBalance,
                              balance: profile?.balance ?? 0,
                              onToggle: onToggleBalance,
                            )
                          : const Text(
                              'Войдите для доступа ко всем функциям',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: isLoggedIn
                    ? onTopUp
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: .18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isLoggedIn ? 'Пополнить' : 'Войти'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1F2E), Color(0xFF23233A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          _CircleSkeleton(size: 72),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(widthFactor: 0.6, height: 18),
                SizedBox(height: 10),
                _SkeletonLine(widthFactor: 0.4, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.isLoggedIn});
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isLoggedIn
                ? const LinearGradient(
                    colors: [Color(0xFFA363D9), Color(0xFF6C5CE7)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF2A2B45), Color(0xFF2A2B45)],
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        if (isLoggedIn)
          const Positioned(bottom: 0, right: 0, child: _OnlineDot()),
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF00B894),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x8000B894), blurRadius: 8)],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 12),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.show,
    required this.balance,
    required this.onToggle,
  });
  final bool show;
  final int balance;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(
            show ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            show ? 'Баланс: $balance ₸' : 'Баланс: ••••• ₸',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final d = profile?.discount ?? 0;
    if (d <= 0) return const SizedBox.shrink();

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
            color: const Color(0xFFFF9F43).withValues(alpha: .35),
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
              color: Colors.white.withValues(alpha: .2),
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
              ],
            ),
          ),
          Text(
            '$d%',
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

class _TariffsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          const Text(
            'Тарифы',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.layers_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: .7),
          ),
        ],
      ),
    );
  }
}

class _TariffList extends StatelessWidget {
  const _TariffList({
    required this.loading,
    required this.tariffs,
    required this.selectedZone,
    required this.discount,
  });

  final bool loading;
  final List<Tariff> tariffs;
  final String selectedZone;
  final int discount;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    if (tariffs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2E).withValues(alpha: .6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: const Text(
          'Для выбранной зоны тарифов нет',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) => _TariffCard(
        tariff: tariffs[i],
        zone: selectedZone,
        discount: discount,
        onTap: () {
          // TODO: flow покупки/брони
        },
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: tariffs.length,
    );
  }
}

class _TariffCard extends StatelessWidget {
  const _TariffCard({
    required this.tariff,
    required this.zone,
    required this.discount,
    this.onTap,
  });
  final Tariff tariff;
  final String zone;
  final int discount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int? price =
        tariff.zonePrices[zone]; // сервер отдаёт уже для выбранной зоны
    if (price == null) return const SizedBox.shrink();
    final bool hasDiscount = discount > 0;
    final int discounted = hasDiscount
        ? (price * (100 - discount) ~/ 100)
        : price;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F2E).withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.computer_rounded,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tariff.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ZonePill(zone: zone),
                      ],
                    ),
                    if (tariff.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tariff.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (hasDiscount)
                      Row(
                        children: [
                          Text(
                            '$price ₸',
                            style: const TextStyle(
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$discounted ₸',
                            style: const TextStyle(
                              color: Color(0xFF00B894),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '$price ₸',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (tariff.minutes > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '(${tariff.minutes} мин)',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZonePill extends StatelessWidget {
  const _ZonePill({required this.zone});
  final String zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        zone.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            const _ActionCard(
              title: 'История операций',
              icon: Icons.history_rounded,
              color: Color(0xFF18DCFF),
            ),
            _ActionCard(
              title: 'Настройки',
              icon: Icons.settings_rounded,
              color: const Color(0xFF7D5FFF),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const _ActionCard(
              title: 'Помощь',
              icon: Icons.help_rounded,
              color: Color(0xFFFF7676),
            ),
            const _ActionCard(
              title: 'О приложении',
              icon: Icons.info_rounded,
              color: Color(0xFF00B894),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F2E).withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== SHEETS / DIALOGS =====================

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.onSubmit});
  final Future<bool> Function(int amount) onSubmit;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final controller = TextEditingController();
  final presets = const [1000, 2000, 5000, 10000, 20000];
  int? selected;
  bool submitting = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = (controller.text.trim().isEmpty)
        ? selected?.toString() ?? ''
        : controller.text.trim();
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      AppSnack.show(
        context,
        message: 'Укажи сумму пополнения',
        type: AppSnackType.error,
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final ok = await widget.onSubmit(amount);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, amount);
      } else {
        AppSnack.show(
          context,
          message: 'Не удалось обновить профиль',
          type: AppSnackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: 'Ошибка пополнения: $e',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Пополнение',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((v) {
              final sel = selected == v;
              return ChoiceChip(
                label: Text('$v ₸'),
                selected: sel,
                onSelected: (_) => setState(() {
                  selected = v;
                  controller.text = selected.toString();
                }),
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: const Color(0xFF6C5CE7),
                backgroundColor: Colors.white.withValues(alpha: .06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: sel
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withValues(alpha: .08),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Другая сумма',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.payments_rounded,
                color: Colors.white70,
              ),
              hintText: 'Например, 3500',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .06),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_card_rounded),
                  label: const Text('Пополнить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7676),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text('Выход', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        'Вы уверены, что хотите выйти из аккаунта?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Выйти',
            style: TextStyle(color: Color(0xFFFF7676)),
          ),
        ),
      ],
    );
  }
}

// ===================== skeletons =====================

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.height});
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B45),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _CircleSkeleton extends StatelessWidget {
  const _CircleSkeleton({this.size = 64});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2B45),
        shape: BoxShape.circle,
      ),
    );
  }
}
