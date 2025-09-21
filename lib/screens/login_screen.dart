import 'package:flutter/material.dart';
import 'package:qube/models/user_token.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';

final api = ApiService.instance;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserToken userToken = await api.login(
        username: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        if (userToken.token.isNotEmpty) {
          AuthStorage.saveToken(userToken.token);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Успешный вход")));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Авторизация",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Имя пользователя",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty
                      ? "Введите имя пользователя"
                      : null,
                ),
                const SizedBox(height: 16),

                // Пароль
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Пароль",
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Введите пароль" : null,
                ),
                const SizedBox(height: 24),

                // Кнопка "Войти"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Войти"),
                  ),
                ),
                const SizedBox(height: 12),

                // Ссылки
                TextButton(
                  onPressed: () {
                    // переход на регистрацию
                  },
                  child: const Text("Создать аккаунт"),
                ),
                TextButton(
                  onPressed: () {
                    // переход на восстановление пароля
                  },
                  child: const Text("Забыли пароль?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
