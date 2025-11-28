import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1),
        ),
      ),
    );
  }
}
