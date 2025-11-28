class Ticket {
  final int id;
  final String name;
  final int price;
  final double durationHours;
  final String description;
  final String color;
  final List<String> availablePeriods;
  final String? expirationInfo;
  final bool isDiscountable;
  final List<int> zones;
  final String originalPrice;

  Ticket({
    required this.id,
    required this.name,
    required this.price,
    required this.durationHours,
    required this.description,
    required this.color,
    required this.availablePeriods,
    this.expirationInfo,
    required this.isDiscountable,
    required this.zones,
    required this.originalPrice,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      durationHours: (json['duration_hours'] ?? 1.0).toDouble(),
      description: json['description'] ?? '',
      color: json['color'] ?? '#1976D2',
      availablePeriods: List<String>.from(json['available_periods'] ?? []),
      expirationInfo: json['expiration_info'],
      isDiscountable: json['is_discountable'] ?? false,
      zones: List<int>.from(json['zones'] ?? []),
      originalPrice: json['original_price'] ?? '0',
    );
  }

  bool isAvailableForZone(int zoneId) {
    return zones.contains(zoneId);
  }
}
