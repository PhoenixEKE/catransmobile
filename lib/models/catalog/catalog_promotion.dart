class CatalogPromotion {
  final String id;
  final String title;
  final String text;
  final String? imageUrl;
  final int displayOrder;

  const CatalogPromotion({
    required this.id,
    required this.title,
    required this.text,
    this.imageUrl,
    required this.displayOrder,
  });

  factory CatalogPromotion.fromJson(Map<String, dynamic> json) {
    return CatalogPromotion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      displayOrder: _readInt(json['display_order']),
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
