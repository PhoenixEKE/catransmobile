import 'package:catrans_app/models/trip/client_trip.dart';

class ClientTripListResponse {
  final String scope;
  final int count;
  final List<ClientTrip> results;

  const ClientTripListResponse({
    required this.scope,
    required this.count,
    required this.results,
  });

  factory ClientTripListResponse.fromJson(Map<String, dynamic> json) {
    final results = _readResults(json['results']);

    return ClientTripListResponse(
      scope: _readString(json['scope']) ?? 'all',
      count: _readInt(json['count']) ?? results.length,
      results: results,
    );
  }

  static List<ClientTrip> _readResults(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => ClientTrip.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
