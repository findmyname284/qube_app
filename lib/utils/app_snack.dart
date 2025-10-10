import 'package:flutter/material.dart';

// Если хочешь уметь показывать снэки без context:
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum AppSnackType { success, error, info, warning }

class AppSnack {
  // Быстрый доступ через контекст
  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnack(
      ScaffoldMessenger.of(context),
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  // Глобальный показ (если ты прокинешь appMessengerKey в MaterialApp)
  static void showGlobal(
    String message, {
    AppSnackType type = AppSnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = appMessengerKey.currentState;
    if (messenger == null) return;
    _showSnack(
      messenger,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  // ---- приватное ----
  static void _showSnack(
    ScaffoldMessengerState messenger, {
    required String message,
    required AppSnackType type,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final spec = _spec(type);

    messenger.hideCurrentSnackBar(); // мягко заменим, чтобы не наслаивались
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent, // рендерим свой контейнер
        content: _SnackContent(
          icon: spec.icon,
          bg: spec.bg,
          fg: spec.fg,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  static _SnackSpec _spec(AppSnackType type) {
    switch (type) {
      case AppSnackType.success:
        return _SnackSpec(
          bg: const Color(0xFF00B894), // зелёный как в твоём UI
          fg: Colors.white,
          icon: Icons.check_circle_rounded,
        );
      case AppSnackType.error:
        return _SnackSpec(
          bg: const Color(0xFFFF7676), // красный как в диалоге выхода
          fg: Colors.white,
          icon: Icons.error_rounded,
        );
      case AppSnackType.warning:
        return _SnackSpec(
          bg: const Color(0xFFFFC048), // янтарный как статус booked
          fg: const Color(0xFF1E1F2E),
          icon: Icons.warning_amber_rounded,
        );
      case AppSnackType.info:
        return _SnackSpec(
          bg: const Color(0xFF6C5CE7), // фиолетовый как градиент в профиле
          fg: Colors.white,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackSpec {
  final Color bg;
  final Color fg;
  final IconData icon;
  _SnackSpec({required this.bg, required this.fg, required this.icon});
}

class _SnackContent extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackContent({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Под стиль: полупрозрачная тёмная карточка
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: bg, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                backgroundColor: bg.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            splashRadius: 18,
            tooltip: 'Закрыть',
          ),
        ],
      ),
    );
  }
}
