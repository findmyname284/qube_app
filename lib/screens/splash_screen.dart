import 'package:flutter/material.dart';
import 'package:qube/main.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/tariff.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/helper.dart';

final api = ApiService.instance;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _msg = "Подключаемся к серверу...";
  bool _loading = true;
  bool _error = false;

  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _logoScale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    _loadData();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setStateSafe(() {
      _loading = true;
      _error = false;
      _msg = "Подключаемся к серверу...";
    });

    try {
      // параллельная загрузка
      final (
        List<Computer> computers,
        Profile? profile,
        List<Tariff> tariffs,
      ) = await (
        api.fetchComputers(),
        api.getProfile(),
        api.fetchTariffs(),
      ).wait;

      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainPage(
            computers: computers,
            profile: profile,
            tariffs: tariffs,
          ),
        ),
      );
    } catch (e) {
      setStateSafe(() {
        _loading = false;
        _error = true;
        _msg =
            "Не удалось загрузить данные.\nПроверьте соединение и попробуйте снова.\n\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // единый фон приложения
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // тонкая верхняя полоска прогресса пока грузимся
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _loading && !_error ? 2.5 : 0,
                  child: _loading && !_error
                      ? const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          minHeight: 2.5,
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // центр
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: const Image(
                              image: AssetImage("assets/images/logo.png"),
                              height: 120,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Загрузка клуба...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // LOADING
                      if (_loading && !_error) ...[
                        const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatusPill(
                          icon: Icons.wifi_tethering_rounded,
                          text: _msg,
                        ),
                      ],

                      // ERROR CARD
                      if (_error) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E1F2E,
                            ).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFFF7676),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Не удалось загрузить данные",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _msg,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Повторить"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // маленький подвал (опционально: версия/копирайт)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    "© Qube Club",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

// компактная «пилюля»-строка статуса, как в остальных экранах
class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatusPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
