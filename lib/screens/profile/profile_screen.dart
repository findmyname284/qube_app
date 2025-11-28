import 'package:flutter/material.dart';
import 'package:qube/models/bonuses.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/screens/profile/dialogs/logout_dialog.dart';
import 'package:qube/screens/profile/dialogs/top_up_confirmation_dialog.dart';
import 'package:qube/screens/profile/dialogs/top_up_sheet.dart';
import 'package:qube/screens/profile/models/tariff.dart';
import 'package:qube/screens/profile/models/ticket.dart';
import 'package:qube/screens/profile/models/zone.dart';
import 'package:qube/screens/profile/widgets/discount_card.dart';
import 'package:qube/screens/profile/widgets/profile_header.dart';
import 'package:qube/screens/profile/widgets/quick_actions.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/utils/helper.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class ProfileScreen extends StatefulWidget {
  final List<Tariff>? tariffs;
  final Profile? profile;
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
  bool isLoading = true;
  bool isLoggedIn = false;
  Profile? profile;
  bool _showBalance = true;

  // --- скидка ---
  double? _discount;
  bool _discountLoading = false;

  // --- тарифы и зоны ---
  List<Zone> _zones = [];
  List<Tariff> _tariffs = [];
  List<Ticket> _tickets = [];
  Zone? _selectedZone;
  bool _tariffsLoading = false;

  @override
  void initState() {
    super.initState();

    // Загружаем профиль
    if (widget.profile != null) {
      isLoggedIn = true;
      profile = widget.profile;
      isLoading = false;
      _softRefreshInBackground();
    } else {
      Future.microtask(() async {
        await _loadProfile();
        if (isLoggedIn) {
          _loadDiscount();
        }
      });
    }

    // Загружаем тарифы и зоны
    _loadTariffsData();
  }

  // ---------- API: Тарифы и зоны ----------

  Future<void> _loadTariffsData() async {
    setStateSafe(() => _tariffsLoading = true);
    try {
      final zones = await api.fetchZones();
      final tariffs = await api.fetchTariffs();
      final tickets = await api.fetchTickets();

      setStateSafe(() {
        _zones = zones;
        _tariffs = tariffs;
        _tickets = tickets;
        // Выбираем зону по умолчанию
        _selectedZone = zones.firstWhere(
          (zone) => zone.isDefault,
          orElse: () => zones.first,
        );
      });
    } catch (e) {
      print('Error loading tariffs data: $e');
    } finally {
      setStateSafe(() => _tariffsLoading = false);
    }
  }

  List<Tariff> get _filteredTariffs {
    if (_selectedZone == null) return _tariffs;
    return _tariffs.where((tariff) {
      final zonePrice = tariff.zonePrices[_selectedZone!.name.toLowerCase()];
      return zonePrice != null && zonePrice > 0;
    }).toList();
  }

  List<Ticket> get _filteredTickets {
    if (_selectedZone == null) return _tickets;
    return _tickets.where((ticket) {
      return ticket.isAvailableForZone(int.parse(_selectedZone!.id));
    }).toList();
  }

  // ---------- API: Профиль ----------

  Future<void> _softRefreshInBackground() async {
    try {
      final token = await AuthStorage.getAccessToken();
      if (token == null) return;
      final fresh = await api.getProfile();
      if (fresh == null) return;
      if (!mounted) return;
      setStateSafe(() {
        isLoggedIn = true;
        profile = fresh;
      });
      widget.onLoggedIn?.call(fresh);
      _loadDiscount();
    } catch (_) {
      /* тихо */
    }
  }

  Future<void> _loadProfile() async {
    setStateSafe(() => isLoading = true);
    try {
      final token = await AuthStorage.getAccessToken();
      if (token != null) {
        final fetched = await api.getProfile();
        if (!mounted) return;
        setStateSafe(() {
          isLoggedIn = fetched != null;
          profile = fetched;
        });
        if (fetched != null) widget.onLoggedIn?.call(fetched);
      } else {
        if (!mounted) return;
        setStateSafe(() {
          isLoggedIn = false;
          profile = null;
          _discount = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setStateSafe(() {
        isLoggedIn = false;
        profile = null;
        _discount = null;
      });
    } finally {
      if (mounted) setStateSafe(() => isLoading = false);
    }
  }

  // ---------- API: Скидка ----------

  Future<void> _loadDiscount() async {
    if (!isLoggedIn) {
      setStateSafe(() => _discount = null);
      return;
    }

    setStateSafe(() => _discountLoading = true);
    try {
      final discount = await api.getDiscount();
      if (!mounted) return;
      setStateSafe(() => _discount = discount);
    } catch (_) {
      if (!mounted) return;
      setStateSafe(() => _discount = null);
    } finally {
      if (mounted) setStateSafe(() => _discountLoading = false);
    }
  }

  Future<void> _triggerRefresh() async {
    await Future.wait([_loadProfile(), _loadTariffsData()]);
    if (isLoggedIn) {
      await _loadDiscount();
    }
  }

  // ---------- Выход ----------

  Future<void> _logout() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutDialog(),
    );
    if (res != true) return;
    await AuthStorage.clearTokens();
    if (!mounted) return;
    setStateSafe(() {
      isLoggedIn = false;
      profile = null;
      _discount = null;
    });
    widget.onLoggedOut?.call();
    AppSnack.show(
      context,
      message: 'Вы вышли из аккаунта',
      type: AppSnackType.success,
    );
  }

  void _toggleBalanceVisibility() {
    setStateSafe(() => _showBalance = !_showBalance);
  }

  // ---------- Пополнение ----------

  Future<void> _showTopUpSheet() async {
    if (!isLoggedIn) return;

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => TopUpSheet(
        onSubmit: (amount) async {
          final bonuses = await api.calculateBonus(amount);
          if (!mounted) return false;
          final confirmed = await _showTopUpConfirmation(context, bonuses);

          if (confirmed) {
            try {
              await api.topUpBalance(amount);
              final updated = await api.getProfile();
              if (!mounted) return false;
              if (updated != null) {
                setStateSafe(() {
                  profile = updated;
                  isLoggedIn = true;
                });
                _loadDiscount();
                return true;
              }
            } catch (e) {
              if (!mounted) return false;
              AppSnack.show(
                context,
                message: 'Ошибка пополнения: $e',
                type: AppSnackType.error,
              );
            }
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

  Future<bool> _showTopUpConfirmation(
    BuildContext context,
    Bonuses bonuses,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (context) => TopUpConfirmationDialog(bonuses: bonuses),
        ) ??
        false;
  }

  // ---------- Виджеты для тарифов ----------

  Widget _buildZoneSelector() {
    if (_zones.length <= 1) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<Zone>(
              value: _selectedZone,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1F2E),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withOpacity(0.7),
              ),
              items: _zones.map((Zone zone) {
                return DropdownMenuItem<Zone>(
                  value: zone,
                  child: Text(zone.name, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (Zone? newValue) {
                setStateSafe(() {
                  _selectedZone = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffsSection() {
    if (_tariffsLoading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    }

    final filteredTariffs = _filteredTariffs;
    final filteredTickets = _filteredTickets;

    if (filteredTariffs.isEmpty && filteredTickets.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: Color(0xFF6C5CE7),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Тарифы и абонементы',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Селектор зоны
        _buildZoneSelector(),

        // Раздел тарифов
        if (filteredTariffs.isNotEmpty) ...[
          _buildSectionHeader('Тарифы за час', Icons.schedule_rounded),
          const SizedBox(height: 8),
          _buildTariffsGrid(filteredTariffs),
          const SizedBox(height: 24),
        ],

        // Раздел абонементов
        if (filteredTickets.isNotEmpty) ...[
          _buildSectionHeader('Абонементы', Icons.confirmation_number_rounded),
          const SizedBox(height: 8),
          _buildTicketsList(filteredTickets),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffsGrid(List<Tariff> tariffs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tariffs.map((tariff) => _buildTariffCard(tariff)).toList(),
      ),
    );
  }

  Widget _buildTariffCard(Tariff tariff) {
    final price = _selectedZone != null
        ? tariff.getPriceForZone(_selectedZone!.name.toLowerCase())
        : tariff.price;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Цветная полоска и название
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(_parseColor(tariff.color)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tariff.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Время
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${tariff.minutes} мин',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Цена
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$price ₽',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (tariff.useDiscount && tariff.discountApplied > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${tariff.discountApplied}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<Ticket> tickets) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: tickets.map((ticket) => _buildTicketCard(ticket)).toList(),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(_parseColor(ticket.color)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ticket.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (ticket.isDiscountable)
                const Icon(
                  Icons.discount_outlined,
                  color: Colors.green,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Длительность
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '${ticket.durationHours.toStringAsFixed(1)} часов',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Период доступности
          if (ticket.availablePeriods.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ticket.availablePeriods.join(', '),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Срок действия
          if (ticket.expirationInfo != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  ticket.expirationInfo!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Цена
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ticket.price} ₽',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Купить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _parseColor(String colorHex) {
    try {
      return int.parse(colorHex.replaceAll('#', '0xFF'));
    } catch (e) {
      return 0xFF1976D2; // default blue
    }
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
                  color: Colors.white.withOpacity(.1),
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
              // Шапка профиля
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ProfileHeader(
                      isLoading: isLoading,
                      isLoggedIn: isLoggedIn,
                      profile: profile,
                      showBalance: _showBalance,
                      onToggleBalance: _toggleBalanceVisibility,
                      onTopUp: isLoggedIn
                          ? _showTopUpSheet
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                              _triggerRefresh();
                            },
                    ),
                    const SizedBox(height: 12),
                    if (!isLoading)
                      DiscountCard(
                        discount: _discount,
                        discountLoading: _discountLoading,
                        isLoggedIn: isLoggedIn,
                      ),
                  ]),
                ),
              ),

              // Тарифы и абонементы
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                sliver: SliverToBoxAdapter(child: _buildTariffsSection()),
              ),

              // Быстрые действия
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: QuickActions(isLoading: isLoading),
                ),
              ),

              // Индикатор загрузки профиля
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

  @override
  bool get wantKeepAlive => true;
}
