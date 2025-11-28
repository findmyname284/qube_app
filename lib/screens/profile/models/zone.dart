class Zone {
  final String id;
  final String name;
  final bool isDefault;

  Zone({required this.id, required this.name, required this.isDefault});

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }
}
