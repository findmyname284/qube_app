import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
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
            _ActionCard(
              title: 'История операций',
              icon: Icons.history_rounded,
              color: const Color(0xFF18DCFF),
            ),
            const _ActionCard(
              title: 'Настройки',
              icon: Icons.settings_rounded,
              color: Color(0xFF7D5FFF),
            ),
            const _ActionCard(
              title: 'Помощь',
              icon: Icons.help_rounded,
              color: Color(0xFFFF7676),
            ),
            const _ActionCard(
              title: 'О приложении',
              icon: Icons.info_rounded,
              color: Color(0xFF00B894),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2E).withOpacity(.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
