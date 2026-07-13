import 'package:catrans_app/models/catalog/catalog_departure.dart';

class CatalogDepartureListResponse {
  final String stationId;
  final String destinationCityId;
  final String date;
  final int? limit;
  final int count;
  final int totalCount;
  final bool hasMore;
  final List<CatalogDeparture> results;

  const CatalogDepartureListResponse({
    required this.stationId,
    required this.destinationCityId,
    required this.date,
    this.limit,
    required this.count,
    required this.totalCount,
    required this.hasMore,
    required this.results,
  });

  factory CatalogDepartureListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];

    return CatalogDepartureListResponse(
      stationId: json['station_id'] as String,
      destinationCityId: json['destination_city_id'] as String,
      date: json['date'] as String,
      limit: json['limit'] as int?,
      count: json['count'] as int,
      totalCount: json['total_count'] as int,
      hasMore: json['has_more'] == true,
      results: rawResults is List
          ? rawResults
              .map((item) => CatalogDeparture.fromJson(_readObject(item)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'station_id': stationId,
        'destination_city_id': destinationCityId,
        'date': date,
        'limit': limit,
        'count': count,
        'total_count': totalCount,
        'has_more': hasMore,
        'results': results.map((departure) => departure.toJson()).toList(),
      };

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}
