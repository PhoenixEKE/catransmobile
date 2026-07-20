import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_dashboard_models.dart';

class AdminDashboardApiService {
  final ApiClient _apiClient;

  AdminDashboardApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AdminDashboardResponse> getOverview({DateTime? date}) {
    return _getDashboard('admin/dashboard/overview/', date: date);
  }

  Future<AdminDashboardResponse> getRevenueByPaymentMethod({DateTime? date}) {
    return _getDashboard('admin/dashboard/revenue-by-payment-method/',
        date: date);
  }

  Future<AdminDashboardResponse> getSalesByChannel({DateTime? date}) {
    return _getDashboard('admin/dashboard/sales-by-channel/', date: date);
  }

  Future<AdminDashboardResponse> getTopRoutes({DateTime? date}) {
    return _getDashboard('admin/dashboard/top-routes/', date: date);
  }

  Future<AdminDashboardResponse> _getDashboard(String path,
      {DateTime? date}) async {
    final response = await _apiClient.get(
      path,
      queryParameters: {
        if (date != null) 'date': _formatDate(date),
      },
    );
    return AdminDashboardResponse.fromJson(_readMap(response.data));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

Map<String, dynamic> _readMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw ApiException(
      message: 'Réponse dashboard admin invalide.', details: data);
}
