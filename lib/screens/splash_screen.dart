import 'package:flutter/material.dart';
import 'package:qube/main.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/services/api_service.dart';

final api = ApiService.instance;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _msg = "Загрузка...";
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = false;
      _msg = "Подключаемся к серверу...";
    });

    try {
      final (List<Computer> computers, Profile? profile) = await (
        api.fetchComputers(),
        api.getProfile(),
      ).wait;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainPage(computers: computers, profile: profile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _msg =
            "Не удалось загрузить данные. Проверьте соединение и попробуйте снова. $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage("assets/images/logo.png"),
              height: 130,
            ),
            const SizedBox(height: 20),
            const Text("Загрузка клуба...", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),

            if (_loading && !_error) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(_msg),
            ],

            if (_error) ...[
              Text(_msg, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Повторить"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
