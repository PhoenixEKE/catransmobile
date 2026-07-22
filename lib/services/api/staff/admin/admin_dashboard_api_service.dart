import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_dashboard_models.dart';

class AdminDashboardApiService {
  final ApiClient _apiClient;

  AdminDashboardApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<AdminDashboardOverviewResponse> getOverview({DateTime? date}) async {
    final json = await _getDashboard('admin/dashboard/overview/', date: date);
    return AdminDashboardOverviewResponse.fromJson(json);
  }

  Future<AdminDashboardRevenueByPaymentMethodResponse>
      getRevenueByPaymentMethod({DateTime? date}) async {
    final json = await _getDashboard(
      'admin/dashboard/revenue-by-payment-method/',
      date: date,
    );
    return AdminDashboardRevenueByPaymentMethodResponse.fromJson(json);
  }

  Future<AdminDashboardSalesByChannelResponse> getSalesByChannel(
      {DateTime? date}) async {
    final json = await _getDashboard(
      'admin/dashboard/sales-by-channel/',
      date: date,
    );
    return AdminDashboardSalesByChannelResponse.fromJson(json);
  }

  Future<AdminDashboardTopRoutesResponse> getTopRoutes({DateTime? date}) async {
    final json = await _getDashboard('admin/dashboard/top-routes/', date: date);
    return AdminDashboardTopRoutesResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _getDashboard(String path,
      {DateTime? date}) async {
    final response = await _apiClient.get(
      path,
      queryParameters: {
        if (date != null) 'date': _formatDate(date),
      },
    );
    return _readMap(response.data);
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
