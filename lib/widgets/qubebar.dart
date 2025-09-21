import 'package:flutter/material.dart';

class QubeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;

  const QubeAppBar({
    super.key,
    required this.title,
    this.icon = Icons.sports_esports, // по умолчанию 🎮
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(icon, size: 26, color: Colors.amber),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
