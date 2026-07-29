import 'dart:typed_data';

import 'package:catrans_app/models/staff/paged_result.dart';

class AdminPromotion {
  final String id;
  final String title;
  final String text;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final JsonMap raw;

  const AdminPromotion({
    required this.id,
    required this.title,
    required this.text,
    this.imageUrl,
    required this.displayOrder,
    required this.isActive,
    this.raw = const {},
  });

  factory AdminPromotion.fromJson(JsonMap json) {
    return AdminPromotion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      displayOrder: _readInt(json['display_order']),
      isActive: json['is_active'] as bool? ?? true,
      raw: json,
    );
  }
}

class AdminPromotionWriteRequest {
  final String title;
  final String text;
  final bool isActive;
  final Uint8List? imageBytes;
  final String? imageFileName;

  const AdminPromotionWriteRequest({
    required this.title,
    required this.text,
    required this.isActive,
    this.imageBytes,
    this.imageFileName,
  });
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
