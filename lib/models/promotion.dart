class Promotion {
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? endDate;

  Promotion({
    required this.title,
    required this.description,
    this.imageUrl,
    this.endDate,
  });
}
