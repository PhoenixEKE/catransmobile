class CatalogPopularRoute {
  final String id;
  final String departureStationName;
  final String destinationName;
  final int popularityCount;
  final double? fareAmount;
  final String? currency;

  const CatalogPopularRoute({
    required this.id,
    required this.departureStationName,
    required this.destinationName,
    required this.popularityCount,
    this.fareAmount,
    this.currency,
  });

  factory CatalogPopularRoute.fromJson(Map<String, dynamic> json) {
    final station = _readObject(json['station']);
    final destination = _readObject(json['destination']);
    final fare = _readObject(json['fare']);
    return CatalogPopularRoute(
      id: json['id']?.toString() ?? '',
      departureStationName: station?['name']?.toString() ?? '',
      destinationName: destination?['name']?.toString() ??
          json['destination_name_snapshot']?.toString() ??
          '',
      popularityCount: _readInt(json['popularity_count']),
      fareAmount: _readDouble(fare?['amount']),
      currency: fare?['currency']?.toString(),
    );
  }
}

Map<String, dynamic>? _readObject(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
