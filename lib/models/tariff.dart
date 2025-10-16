class Tariff {
  final String id;
  final String title;
  final int minutes;
  final int price;
  final String description;
  final Map<String, int> zonePrices; // новое
  final int discountApplied; // новое (%)

  /// Новое: если заданы, тариф фикс-окна по времени суток
  /// Формат: "HH:mm" (например, "22:00" и "08:00")
  final String? startAt; // локальное время начала окна
  final String? endAt; // локальное время конца окна

  Tariff({
    required this.id,
    required this.title,
    required this.minutes,
    required this.price,
    required this.description,
    this.zonePrices = const {},
    this.discountApplied = 0,
    this.startAt,
    this.endAt,
  });

  bool get isFixedWindow =>
      (startAt != null && startAt!.isNotEmpty) &&
      (endAt != null && endAt!.isNotEmpty);

  factory Tariff.fromJson(Map<String, dynamic> json) {
    final zpRaw = (json['zone_prices'] as Map?) ?? const {};
    final zp = <String, int>{};
    for (final entry in zpRaw.entries) {
      final v = entry.value;
      if (v is num) zp['${entry.key}'] = v.toInt();
    }
    return Tariff(
      id: json['id'] as String,
      title: (json['title'] ?? '').toString(),
      minutes: (json['minutes'] ?? 0) as int,
      price: (json['price'] ?? 0) as int,
      description: (json['description'] ?? '').toString(),
      zonePrices: zp,
      discountApplied: (json['discount_applied'] ?? 0) as int,
      startAt: (json['start_at'] as String?)?.trim(), // новое
      endAt: (json['end_at'] as String?)?.trim(), // новое
    );
  }
}
