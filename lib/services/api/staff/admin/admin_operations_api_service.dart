import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';

class AdminOperationsApiService {
  final ApiClient _apiClient;

  AdminOperationsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<PagedResult<AdminOperationRecord>> listSeatLayouts({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/operations/seat-layouts/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<AdminOperationRecord> getSeatLayout(String id) =>
      _get('admin/operations/seat-layouts/$id/');

  Future<PagedResult<AdminOperationRecord>> listDepartureTemplates({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/operations/departure-templates/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<AdminOperationRecord> getDepartureTemplate(String id) =>
      _get('admin/operations/departure-templates/$id/');

  Future<PagedResult<AdminOperationRecord>> listDepartures({
    String? query,
    String? status,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list(
        'admin/operations/departures/',
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: {'status': status?.trim()},
      );

  Future<AdminOperationRecord> getDeparture(String id) =>
      _get('admin/operations/departures/$id/');

  Future<Map<String, dynamic>> getDepartureSeatMap(String departureId) async {
    final response = await _apiClient
        .get('admin/operations/departures/$departureId/seat-map/');
    return _readMap(response.data);
  }

  Future<Map<String, dynamic>> previewDepartures(String templateId) async {
    final response = await _apiClient.get(
        'admin/operations/departure-templates/$templateId/departures/preview/');
    return _readMap(response.data);
  }

  Future<AdminOperationActionResponse> generateDepartures(
      String templateId) async {
    final response = await _apiClient.post(
        'admin/operations/departure-templates/$templateId/departures/generate/');
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<AdminOperationActionResponse> generateSeats(String departureId) async {
    final response = await _apiClient
        .post('admin/operations/departures/$departureId/generate-seats/');
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<AdminOperationActionResponse> blockSeats(
      String departureId, List<int> seatNumbers) async {
    final response = await _apiClient.post(
      'admin/operations/departures/$departureId/seats/block/',
      data: {'seat_numbers': seatNumbers},
    );
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<AdminOperationActionResponse> unblockSeats(
      String departureId, List<int> seatNumbers) async {
    final response = await _apiClient.post(
      'admin/operations/departures/$departureId/seats/unblock/',
      data: {'seat_numbers': seatNumbers},
    );
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<void> openDeparture(String departureId) async {
    await _apiClient.post('admin/operations/departures/$departureId/open/');
  }

  Future<void> closeDeparture(String departureId) async {
    await _apiClient.post('admin/operations/departures/$departureId/close/');
  }

  Future<void> markDeparted(String departureId) async {
    await _apiClient.post('admin/operations/departures/$departureId/depart/');
  }

  Future<void> cancelDeparture(String departureId) async {
    await _apiClient.post('admin/operations/departures/$departureId/cancel/');
  }

  Future<PagedResult<AdminOperationRecord>> _list(
    String path, {
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic> extra = const {},
  }) async {
    final response = await _apiClient.get(
      path,
      queryParameters: buildAdminOperationsQueryParameters(
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: extra,
      ),
    );
    return PagedResult.fromJson(response.data, AdminOperationRecord.fromJson);
  }

  Future<AdminOperationRecord> _get(String path) async {
    final response = await _apiClient.get(path);
    return AdminOperationRecord.fromJson(_readMap(response.data));
  }
}

Map<String, dynamic> buildAdminOperationsQueryParameters({
  String? query,
  bool? isActive,
  String? ordering,
  int page = 1,
  int pageSize = 20,
  Map<String, dynamic> extra = const {},
}) {
  final result = <String, dynamic>{
    'page': page < 1 ? 1 : page,
    'page_size': pageSize.clamp(1, 100),
    if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    if (isActive != null) 'is_active': isActive,
    if (ordering != null && ordering.trim().isNotEmpty)
      'ordering': ordering.trim(),
  };
  for (final entry in extra.entries) {
    final value = entry.value;
    if (value == null) continue;
    if (value is String && value.isEmpty) continue;
    result[entry.key] = value;
  }
  return result;
}

Map<String, dynamic> _readMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw ApiException(
      message: 'Réponse opérations admin invalide.', details: data);
}
