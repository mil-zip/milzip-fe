class Place {
  final String id;
  final String name;
  final List<String> categories;
  final String? militaryDiscount;
  final double distanceKm;
  final bool isMilzipRecommended;
  final String? imageUrl;

  const Place({
    required this.id,
    required this.name,
    required this.categories,
    this.militaryDiscount,
    required this.distanceKm,
    this.isMilzipRecommended = false,
    this.imageUrl,
  });
}
