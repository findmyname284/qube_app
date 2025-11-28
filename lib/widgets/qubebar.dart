import 'package:flutter/material.dart';

class QubeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final bool? showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final IconButton? leading;

  const QubeAppBar({
    super.key,
    required this.title,
    this.icon = Icons.sports_esports,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA363D9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
      leading: Navigator.of(context).canPop() && (showBackButton ?? false)
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }
}
