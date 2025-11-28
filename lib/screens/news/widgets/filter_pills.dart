import 'package:flutter/material.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C5CE7)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C5CE7)
                : Colors.white.withOpacity(0.08),
          ),
          boxShadow: selected
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
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
