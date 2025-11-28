import 'package:flutter/material.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

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
