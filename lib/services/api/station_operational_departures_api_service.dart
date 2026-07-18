import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';

class StationOperationalDeparturesApiService {
  final ApiClient _apiClient;

  StationOperationalDeparturesApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<StationOperationalDeparturesResponse> getOperationalDepartures({
    DateTime? date,
    int page = 1,
    int pageSize = 20,
    List<String>? statuses,
    String? serviceClassId,
    String? search,
  }) async {
    final statusValue = statuses
        ?.map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .join(',');
    final queryParameters = <String, dynamic>{
      if (date != null) 'date': _formatDate(date),
      'page': page,
      'page_size': pageSize,
      if (statusValue != null && statusValue.isNotEmpty) 'status': statusValue,
      if (serviceClassId != null && serviceClassId.trim().isNotEmpty)
        'service_class_id': serviceClassId.trim(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final response = await _apiClient.get(
      'station/departures/operational/',
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationOperationalDeparturesResponse.fromJson(data);
    }
    if (data is Map) {
      return StationOperationalDeparturesResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse des départs opérationnels invalide.',
      details: data,
    );
  }

  Future<void> openDeparture(String departureId) async {
    await _apiClient.post('station/departures/$departureId/open/');
  }

  Future<void> closeDeparture(String departureId) async {
    await _apiClient.post('station/departures/$departureId/close/');
  }

  Future<void> markDepartureAsDeparted(String departureId) async {
    await _apiClient.post('station/departures/$departureId/depart/');
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
