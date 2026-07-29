import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/dashboard/station_dashboard_overview.dart';

class StationDashboardApiService {
  final ApiClient _apiClient;

  StationDashboardApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<StationDashboardOverview> getOverview({
    DateTime? date,
    String? stationId,
  }) async {
    final response = await _apiClient.get(
      'station/dashboard/overview/',
      queryParameters: {
        if (date != null) 'date': _formatDate(date),
        if (stationId != null && stationId.trim().isNotEmpty)
          'station_id': stationId.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationDashboardOverview.fromJson(data);
    }
    if (data is Map) {
      return StationDashboardOverview.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse tableau de bord gare invalide.',
      details: data,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
