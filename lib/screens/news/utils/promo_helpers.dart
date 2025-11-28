import 'package:flutter/material.dart';

List<Color> autoGradient(int seed) {
  const presets = [
    [Color(0xFF6C5CE7), Color(0xFFA363D9)],
    [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
    [Color(0xFF18DCFF), Color(0xFF7D5FFF)],
    [Color(0xFF00B894), Color(0xFF00CEC9)],
  ];
  return presets[seed % presets.length];
}
