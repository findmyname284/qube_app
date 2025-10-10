import 'package:flutter/material.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/tariff.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/utils/helper.dart';
import 'package:qube/widgets/qubebar.dart';
import 'package:qube/widgets/zone_chips.dart';

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

class _ProfileScreenState extends State<ProfileScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  // --- профиль ---
  bool isLoading = true; // загрузка профиля
  bool isLoggedIn = false;
  Profile? profile;
  bool _showBalance = true;

  // --- тарифы ---
  List<Tariff> _tariffs = const [];
  bool _tariffsLoading = false;

  // если у тебя есть /zones — лучше загрузить реально с сервера.
  // пока дефолт + поверх него добавим ключи из пришедших тарифов (если есть)
  List<String> _zones = ['main', 'vip', 'pro', 'premium', 'premium2'];
  String _selectedZone = 'main';

  @override
  void initState() {
    super.initState();

    // стартовые данные по тарифам, если пришли сверху
    if (widget.tariffs != null && widget.tariffs!.isNotEmpty) {
      _tariffs = widget.tariffs!;
      // соберём доступные зоны из zonePrices
      final fromTariffs = widget.tariffs!
          .expand((t) => t.zonePrices.keys)
          .map((e) => e.toString())
          .toSet();
      if (fromTariffs.isNotEmpty) {
        _zones = fromTariffs.toList()..sort();
        // выберем безопасно первую доступную зону, если там нет main
        if (!_zones.contains(_selectedZone)) {
          _selectedZone = _zones.first;
        }
      }
    } else {
      // если ничего не передали — сразу грузим тарифы под выбранную зону
      _loadTariffsForZone(_selectedZone);
    }

    // профиль: если передали — показываем сразу
    if (widget.profile != null) {
      isLoggedIn = true;
      profile = widget.profile;
      isLoading = false;
      _softRefreshInBackground();
    } else {
      // иначе грузим
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
      setStateSafe(() {
        isLoggedIn = true;
        profile = fresh;
      });
      widget.onLoggedIn?.call(fresh);
    } catch (_) {
      /* тихо */
    }
  }

  Future<void> _loadProfile() async {
    setStateSafe(() => isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      if (token != null) {
        final fetched = await api.getProfile();
        setStateSafe(() {
          isLoggedIn = fetched != null;
          profile = fetched;
        });
        if (fetched != null) widget.onLoggedIn?.call(fetched);
      } else {
        setStateSafe(() {
          isLoggedIn = false;
          profile = null;
        });
      }
    } catch (_) {
      setStateSafe(() {
        isLoggedIn = false;
        profile = null;
      });
    } finally {
      if (mounted) setStateSafe(() => isLoading = false);
    }
  }

  // ---------- API: Тарифы ----------

  Future<void> _loadTariffsForZone(String zone) async {
    setStateSafe(() {
      _tariffsLoading = true;
      // не очищаем _tariffs, чтобы не мигало — можно показать старые пока грузим
    });
    try {
      final t = await api.fetchTariffs(
        zone: zone,
      ); // сервер вернёт price для зоны
      setStateSafe(() => _tariffs = t);
    } catch (_) {
      // Можно показать снек, если нужно:
      // if (mounted) AppSnack.show(context, message: 'Не удалось загрузить тарифы', type: AppSnackType.error);
    } finally {
      if (mounted) setStateSafe(() => _tariffsLoading = false);
    }
  }

  Future<void> _triggerRefresh() async {
    await _loadProfile();
    await _loadTariffsForZone(_selectedZone);
  }

  // ---------- Выход ----------

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const Text("Выход", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "Вы уверены, что хотите выйти из аккаунта?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Отмена",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthStorage.clearToken();
              setStateSafe(() {
                isLoggedIn = false;
                profile = null;
              });
              widget.onLoggedOut?.call();
              if (!context.mounted) return;
              AppSnack.show(
                context,
                message: "Вы вышли из аккаунта",
                type: AppSnackType.success,
              );
            },
            child: const Text(
              "Выйти",
              style: TextStyle(color: Color(0xFFFF7676)),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBalanceVisibility() {
    setStateSafe(() => _showBalance = !_showBalance);
  }

  // ---------- UI блоки ----------

  Widget _buildLoadingHeader() {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1F2E), Color(0xFF23233A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2B45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(widthFactor: 0.6, height: 20),
                SizedBox(height: 12),
                _SkeletonLine(widthFactor: 0.4, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (isLoading) return _buildLoadingHeader();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isLoggedIn
            ? const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [const Color(0xFF1E1F2E), const Color(0xFF1E1F2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isLoggedIn ? const Color(0xFF6C5CE7) : Colors.black)
                .withValues(alpha: .3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isLoggedIn
                      ? const LinearGradient(
                          colors: [Color(0xFFA363D9), Color(0xFF6C5CE7)],
                        )
                      : LinearGradient(colors: [Colors.grey, Colors.grey]),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isLoggedIn
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              if (isLoggedIn)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B894),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0xFF00B894), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isLoggedIn ? (profile?.username ?? "Пользователь") : "Гость",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoggedIn) ...[
            GestureDetector(
              onTap: _toggleBalanceVisibility,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showBalance
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showBalance
                        ? "Баланс: ${profile?.balance ?? 0} ₸"
                        : "Баланс: ••••• ₸",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Пополнить баланс"),
            ),
          ] else ...[
            const Text(
              "Войдите для доступа ко всем функциям",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (result == true) _loadProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Войти / Зарегистрироваться"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    if (isLoading) return const SizedBox();
    if (!isLoggedIn || (profile?.discount ?? 0) <= 0) return const SizedBox();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F43).withValues(alpha: .4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ваша скидка",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  "${profile?.discount ?? 0}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildTariffsHeader() {
    if (isLoading) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          const Text(
            "Тарифы",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.layers_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: .7),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildTariffsSection() {
    if (isLoading) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTariffsHeader(),

        // фильтр зон
        ZoneChips(
          zones: _zones,
          selected: _selectedZone,
          onChanged: (z) {
            if (_selectedZone == z) return;
            setStateSafe(() => _selectedZone = z);
            _loadTariffsForZone(z);
          },
        ),
        const SizedBox(height: 10),

        if (_tariffsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          )
        else if (_tariffs.isEmpty)
          Container(
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
          )
        else
          ..._tariffs.map((tariff) {
            final int price =
                tariff.price; // уже цена для выбранной зоны из сервера
            final bool hasDiscount = isLoggedIn && (profile?.discount ?? 0) > 0;
            final int discountedPrice = hasDiscount
                ? (price * (100 - (profile!.discount ?? 0)) ~/ 100)
                : price;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // старт покупки/брони с tariff.minutes и _selectedZone
                    // TODO: внедрить flow покупки/брони
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1F2E).withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6C5CE7,
                            ).withValues(alpha: .2),
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
                                  Text(
                                    tariff.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tariff.minutes > 0
                                        ? "(${tariff.minutes} мин)"
                                        : "",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _selectedZone.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (tariff.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  tariff.description,
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
                                      "$price ₸",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$discountedPrice ₸",
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
                                  "$price ₸",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildQuickActions() {
    if (isLoading) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "Быстрые действия",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
            _buildActionCard(
              "История операций",
              Icons.history_rounded,
              const Color(0xFF18DCFF),
              () {},
            ),
            _buildActionCard(
              "Настройки",
              Icons.settings_rounded,
              const Color(0xFF7D5FFF),
              () {},
            ),
            _buildActionCard(
              "Помощь",
              Icons.help_rounded,
              const Color(0xFFFF7676),
              () {},
            ),
            _buildActionCard(
              "О приложении",
              Icons.info_rounded,
              const Color(0xFF00B894),
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(
        title: "Профиль",
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildDiscountCard(),
                _buildTariffsSection(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 40),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// простой скелетон
class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  const _SkeletonLine({required this.widthFactor, required this.height});

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
