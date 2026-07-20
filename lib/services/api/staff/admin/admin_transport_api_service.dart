import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_transport_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';

class AdminTransportApiService {
  final ApiClient _apiClient;

  AdminTransportApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<PagedResult<AdminTransportRecord>> listCompanies({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/companies/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<PagedResult<AdminTransportRecord>> listCities({
    String? query,
    String? country,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/cities/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize,
          extra: {'country': country?.trim()});

  Future<PagedResult<AdminTransportRecord>> listStations({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/stations/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<PagedResult<AdminTransportRecord>> listCounters({
    String? stationId,
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) {
    if (stationId != null && stationId.trim().isNotEmpty) {
      return _list('admin/transport/stations/${stationId.trim()}/counters/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);
    }
    return _list('admin/users/counters/',
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize);
  }

  Future<PagedResult<AdminTransportRecord>> listServiceClasses({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/service-classes/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<PagedResult<AdminTransportRecord>> listRoutes({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/routes/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<PagedResult<AdminTransportRecord>> listFares({
    String? query,
    String? currency,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/fares/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize,
          extra: {'currency': currency?.trim()});

  Future<PagedResult<AdminTransportRecord>> listSchedules({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list('admin/transport/schedules/',
          query: query,
          isActive: isActive,
          ordering: ordering,
          page: page,
          pageSize: pageSize);

  Future<AdminTransportRecord> get(String path, String id) async {
    final response = await _apiClient.get('$path/$id/');
    return AdminTransportRecord.fromJson(_readMap(response.data));
  }

  Future<AdminTransportRecord> create(
      String path, AdminTransportWriteRequest request) async {
    final response = await _apiClient.post('$path/', data: request.toJson());
    return AdminTransportRecord.fromJson(_readMap(response.data));
  }

  Future<AdminTransportRecord> update(
      String path, String id, AdminTransportWriteRequest request) async {
    final response =
        await _apiClient.patch('$path/$id/', data: request.toJson());
    return AdminTransportRecord.fromJson(_readMap(response.data));
  }

  Future<AdminTransportRecord> activate(String path, String id) async {
    final response = await _apiClient.post('$path/$id/activate/');
    return _readActionObject(response.data);
  }

  Future<AdminTransportRecord> deactivate(String path, String id) async {
    final response = await _apiClient.post('$path/$id/deactivate/');
    return _readActionObject(response.data);
  }

  Future<PagedResult<AdminTransportRecord>> _list(
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
      queryParameters: buildAdminTransportQueryParameters(
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: extra,
      ),
    );
    return PagedResult.fromJson(response.data, AdminTransportRecord.fromJson);
  }

  AdminTransportRecord _readActionObject(dynamic data) {
    final map = _readMap(data);
    for (final key in [
      'object',
      'company',
      'city',
      'station',
      'counter',
      'route',
      'fare',
      'schedule',
      'service_class'
    ]) {
      final value = map[key];
      if (value is Map) {
        return AdminTransportRecord.fromJson(Map<String, dynamic>.from(value));
      }
    }
    return AdminTransportRecord.fromJson(map);
  }
}

Map<String, dynamic> buildAdminTransportQueryParameters({
  String? query,
  bool? isActive,
  String? ordering,
  int page = 1,
  int pageSize = 20,
  Map<String, dynamic> extra = const {},
}) {
  return _cleanQuery({
    'page': page < 1 ? 1 : page,
    'page_size': pageSize.clamp(1, 100),
    'q': query?.trim(),
    if (isActive != null) 'is_active': isActive,
    'ordering': ordering?.trim(),
    ...extra,
  });
}

Map<String, dynamic> _cleanQuery(Map<String, dynamic> query) {
  final result = <String, dynamic>{};
  for (final entry in query.entries) {
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
      message: 'Réponse transport admin invalide.', details: data);
}
