import 'package:flutter/material.dart';

class ZoneChips extends StatelessWidget {
  final List<String> zones; // ['main','vip','pro','premium','premium2']
  final String selected; // текущая зона
  final ValueChanged<String> onChanged;

  const ZoneChips({
    super.key,
    required this.zones,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: zones.map((z) {
          final bool isSel = z == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(z),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: isSel
                      ? const Color(0xFF6C5CE7)
                      : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: isSel
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withOpacity(0.08),
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  _label(z),
                  style: TextStyle(
                    color: isSel
                        ? Colors.white
                        : Colors.white.withValues(alpha: .75),
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(String key) {
    switch (key) {
      case 'main':
        return 'Обычный';
      case 'vip':
        return 'VIP';
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium';
      case 'premium2':
        return 'Premium+';
      default:
        return key;
    }
  }
}
