import 'package:flutter/material.dart';

class Promotion {
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? endDate;
  final List<Color>? gradient;
  final IconData? icon;

  final String? category;

  Promotion({
    required this.title,
    required this.description,
    this.imageUrl,
    this.endDate,
    this.gradient,
    this.icon,
    this.category,
  });
}
