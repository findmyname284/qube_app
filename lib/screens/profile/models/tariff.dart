class Tariff {
  final int id;
  final String name;
  final int minutes;
  final int price;
  final String description;
  final Map<String, int> zonePrices;
  final int discountApplied;
  final String? startAt;
  final String? endAt;
  final String color;
  final bool useDiscount;

  Tariff({
    required this.id,
    required this.name,
    required this.minutes,
    required this.price,
    required this.description,
    required this.zonePrices,
    required this.discountApplied,
    this.startAt,
    this.endAt,
    required this.color,
    required this.useDiscount,
  });

  factory Tariff.fromJson(Map<String, dynamic> json) {
    return Tariff(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      minutes: json['minutes'] ?? 60,
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      zonePrices: Map<String, int>.from(json['zone_prices'] ?? {}),
      discountApplied: json['discount_applied'] ?? 0,
      startAt: json['start_at'],
      endAt: json['end_at'],
      color: json['color'] ?? '#1976D2',
      useDiscount: json['use_discount'] ?? false,
    );
  }

  int getPriceForZone(String zoneName) {
    return zonePrices[zoneName.toLowerCase()] ?? price;
  }
}
