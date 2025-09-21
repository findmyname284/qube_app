import 'package:flutter/material.dart';
import 'package:qube/models/me.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      isLoggedIn = true;
      profile = widget.profile;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerRefresh();
    });
  }

  Future<void> _triggerRefresh() async {
    _refreshKey.currentState?.show(); // крутилка сверху
    await _loadProfile(); // фактический рефетч
  }

  Future<void> _loadProfile() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      final profile = await api.getProfile();
      if (mounted) {
        setState(() {
          isLoggedIn = true;
          this.profile = profile;
        });
        widget.onLoggedIn?.call(profile!);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          profile = null;
        });
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthStorage.clearToken();
    setState(() {
      isLoggedIn = false;
      profile = null;
    });

    widget.onLoggedOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QubeAppBar(
        title: "Профиль",
        actions: [
          if (isLoggedIn)
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Заголовок профиля ----
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Icon(
                        isLoggedIn ? Icons.person : Icons.person_outline,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLoggedIn
                          ? profile?.username ?? "Пользователь"
                          : "Гость",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isLoggedIn)
                      Text(
                        "Баланс: ${profile?.balance ?? 0} ₸",
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadProfile(); // обновить после входа
                          }
                        },
                        child: const Text("Войти / Зарегистрироваться"),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Скидка ----
              if (isLoggedIn &&
                  profile?.discount != null &&
                  profile!.discount! > 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Ваша скидка: ${profile?.discount ?? 0}%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // ---- Тарифы ----
              Text("Тарифы:", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),

              Column(
                children: widget.tariffs.map((tariff) {
                  final int price = tariff['price'];
                  final int discountedPrice = profile?.discount != null
                      ? (price * (100 - profile!.discount!) ~/ 100)
                      : price;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.computer),
                      title: Text(tariff['title']),
                      subtitle:
                          profile?.discount != null && profile!.discount! > 0
                          ? Row(
                              children: [
                                Text(
                                  "$price ₸",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$discountedPrice ₸",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text("$price ₸"),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
