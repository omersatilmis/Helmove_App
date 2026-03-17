class BusinessPoi {
  final String title;
  final String type;
  final String rating;
  final bool isOpen;
  final String address;
  final String? imageUrl;
  final String? iconUrl;

  const BusinessPoi({
    required this.title,
    required this.type,
    required this.rating,
    required this.isOpen,
    required this.address,
    this.imageUrl,
    this.iconUrl,
  });
}
