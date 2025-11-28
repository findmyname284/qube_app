import 'package:flutter/material.dart';
import 'package:qube/screens/login_screen.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:qube/utils/helper.dart';
import 'package:qube/widgets/qubebar.dart';
import 'package:qube/utils/app_snack.dart';

final api = ApiService.instance;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeWithTerms = false;

  void _validateForm() {
    setStateSafe(() {});
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeWithTerms) {
      AppSnack.show(
        context,
        message: "Примите условия использования",
        type: AppSnackType.warning,
      );
      return;
    }

    setStateSafe(() => _isLoading = true);

    try {
      //   await Future.delayed(const Duration(seconds: 2));
      final token = await api.register(
        _usernameController.text,
        // _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        setStateSafe(() => _isLoading = false);
      }

      if (token.accessToken.isNotEmpty) {
        AuthStorage.saveTokens(token.accessToken, token.refreshToken);
        if (mounted) {
          _showSuccessAnimation();
        }
      }
    } catch (e) {
      if (mounted) {
        setStateSafe(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00B894),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B894).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Аккаунт создан!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, true);
      }
    });
  }

  void _showErrorDialog(String error) {
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
              child: const Icon(Icons.error_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              "Ошибка регистрации",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF6C5CE7))),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _usernameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _agreeWithTerms;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: QubeAppBar(title: "Регистрация", icon: Icons.person_add_rounded),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0F13), Color(0xFF161321), Color(0xFF1A1B2E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B894), Color(0xFF00CEB9)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00B894).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Создайте аккаунт",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "И получите бонусы на первый депозит!",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161821).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          label: "Имя пользователя",
                          icon: Icons.person_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите имя пользователя";
                            }
                            if (value.length < 3) {
                              return "Имя должно быть не менее 3 символов";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите email";
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return "Введите корректный email";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          controller: _passwordController,
                          label: "Пароль",
                          obscureText: _obscurePassword,
                          onToggle: () {
                            setStateSafe(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Введите пароль";
                            }
                            if (value.length < 6) {
                              return "Пароль должен быть не менее 6 символов";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Подтверждение пароля
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: "Подтвердите пароль",
                          obscureText: _obscureConfirmPassword,
                          onToggle: () {
                            setStateSafe(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Подтвердите пароль";
                            }
                            if (value != _passwordController.text) {
                              return "Пароли не совпадают";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Согласие с условиями
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeWithTerms,
                              onChanged: (value) {
                                setStateSafe(
                                  () => _agreeWithTerms = value ?? false,
                                );
                              },
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                return _agreeWithTerms
                                    ? const Color(0xFF00B894)
                                    : Colors.grey.withValues(alpha: 0.3);
                              }),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Показать условия использования
                                },
                                child: const Text(
                                  "Я согласен с условиями использования и политикой конфиденциальности",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Кнопка регистрации
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _isFormValid && !_isLoading
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF00B894),
                                      Color(0xFF00CEB9),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.withValues(alpha: 0.5),
                                      Colors.grey.withValues(alpha: 0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isFormValid && !_isLoading
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00B894,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isFormValid && !_isLoading
                                  ? _register
                                  : null,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Зарегистрироваться",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Уже есть аккаунт? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              ),
                              child: const Text(
                                "Войти",
                                style: TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1F2E),
            const Color(0xFF1E1F2E).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            child: Icon(icon, color: const Color(0xFF00B894)),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1F2E),
            const Color(0xFF1E1F2E).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withValues(alpha: 0.2),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            child: const Icon(Icons.lock_rounded, color: Color(0xFF00B894)),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white70,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }
}
