import 'package:flutter/material.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/widgets/qubebar.dart';

final api = ApiService.instance;

class ProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tariffs;
  final Profile? profile;
  final void Function(Profile)? onLoggedIn;
  final void Function()? onLoggedOut;

  const ProfileScreen({
    super.key,
    required this.tariffs,
    this.profile,
    this.onLoggedIn,
    this.onLoggedOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  bool isLoading = true;
  bool isLoggedIn = false;
  Profile? profile;
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();

    // если профиль уже пришёл «сверху» — показываем сразу (без «гостя»)
    if (widget.profile != null) {
      isLoggedIn = true;
      profile = widget.profile;
      isLoading = false;
      // при желании можно фоном обновить данные, но без мерцаний
      _softRefreshInBackground();
    } else {
      // обычный путь: первая отрисовка = лоадер, затем подгружаем профиль
      Future.microtask(_loadProfile);
    }
  }

  Future<void> _softRefreshInBackground() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;
      final fresh = await api.getProfile();
      if (!mounted || fresh == null) return;
      setState(() {
        isLoggedIn = true;
        profile = fresh;
      });
      widget.onLoggedIn?.call(fresh);
    } catch (_) {
      // молча игнорируем — это фоновое обновление
    }
  }

  Future<void> _triggerRefresh() async {
    // ручное «потянуть-вниз» — обычный рефреш
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
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
        if (fetched != null) {
          widget.onLoggedIn?.call(fetched);
        }
      } else {
        if (!mounted) return;
        setState(() {
          isLoggedIn = false;
          profile = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoggedIn = false;
        profile = null;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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
              if (!mounted) return;
              setState(() {
                isLoggedIn = false;
                profile = null;
              });
              widget.onLoggedOut?.call();

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
    setState(() {
      _showBalance = !_showBalance;
    });
  }

  // ---------- UI ----------

  Widget _buildLoadingHeader() {
    // лёгкий скелетон без пакетов
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
          // аватар-скелет
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2B45),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // текстовые полоски
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
                colors: [
                  const Color(0xFF1E1F2E),
                  const Color(0xFF1E1F2E).withOpacity(0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isLoggedIn ? const Color(0xFF6C5CE7) : Colors.black)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Аватар и статус
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
                      : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.5),
                            Colors.grey.withOpacity(0.3),
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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

          // Имя пользователя
          Text(
            isLoggedIn ? (profile?.username ?? "Пользователь") : "Гость",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // Баланс или CTA
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
              onPressed: () {
                // Пополнение баланса
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                if (result == true) {
                  _loadProfile();
                }
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
    if (!isLoggedIn || profile?.discount == null || profile!.discount! <= 0) {
      return const SizedBox();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F43).withOpacity(0.4),
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
              color: Colors.white.withOpacity(0.2),
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

  Widget _buildTariffsSection() {
    if (isLoading) return const SizedBox();
    if (widget.tariffs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Тарифы",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        ...widget.tariffs.map((tariff) {
          final int price = tariff['price'];
          final bool hasDiscount =
              isLoggedIn && profile?.discount != null && profile!.discount! > 0;
          final int discountedPrice = hasDiscount
              ? (price * (100 - profile!.discount!) ~/ 100)
              : price;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1F2E).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.2),
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
                            Text(
                              tariff['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B894),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "-${profile!.discount}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
            color: const Color(0xFF1E1F2E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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
                  color: Colors.white.withOpacity(0.1),
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

// простой «скелетон»-виджет без зависимостей
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
