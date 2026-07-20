import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';

class AdminUsersApiService {
  final ApiClient _apiClient;

  AdminUsersApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<PagedResult<AdminInternalUserSummary>> listUsers({
    String? query,
    String? role,
    String? stationId,
    String? counterId,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      'admin/users/internal/',
      queryParameters: buildAdminUsersQueryParameters(
        query: query,
        role: role,
        stationId: stationId,
        counterId: counterId,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
      ),
    );

    return PagedResult.fromJson(
      response.data,
      AdminInternalUserSummary.fromJson,
    );
  }

  Future<AdminInternalUserDetail> getUser(String id) async {
    final response = await _apiClient.get('admin/users/internal/$id/');
    return AdminInternalUserDetail.fromJson(_readMap(response.data));
  }

  Future<AdminInternalUserDetail> createUser(
    AdminInternalUserCreateRequest request,
  ) async {
    final response = await _apiClient.post(
      'admin/users/internal/',
      data: request.toJson(),
    );
    return AdminInternalUserDetail.fromJson(_readMap(response.data));
  }

  Future<AdminInternalUserDetail> updateUser(
    String id,
    AdminInternalUserUpdateRequest request,
  ) async {
    final response = await _apiClient.patch(
      'admin/users/internal/$id/',
      data: request.toJson(),
    );
    return AdminInternalUserDetail.fromJson(_readMap(response.data));
  }

  Future<AdminInternalUserDetail> activateUser(String id) async {
    final response =
        await _apiClient.post('admin/users/internal/$id/activate/');
    return AdminInternalUserDetail.fromJson(_readMap(response.data));
  }

  Future<AdminInternalUserDetail> deactivateUser(String id) async {
    final response =
        await _apiClient.post('admin/users/internal/$id/deactivate/');
    return AdminInternalUserDetail.fromJson(_readMap(response.data));
  }

  Future<List<AdminInternalRoleOption>> listRoles() async {
    final response = await _apiClient.get('admin/users/roles/');
    return _readResults(response.data)
        .map(AdminInternalRoleOption.fromJson)
        .toList();
  }

  Future<List<StaffStationRef>> listStations() async {
    final response = await _apiClient.get('admin/users/stations/');
    return _readResults(response.data).map(StaffRef.fromJson).toList();
  }

  Future<List<StaffCounterRef>> listCounters(
      {required String stationId}) async {
    final normalizedStationId = stationId.trim();
    if (normalizedStationId.isEmpty) {
      throw ApiException(
        message: 'La gare est obligatoire pour charger les guichets.',
        statusCode: 400,
      );
    }

    final response = await _apiClient.get(
      'admin/users/counters/',
      queryParameters: {'station_id': normalizedStationId},
    );
    return _readResults(response.data).map(StaffRef.fromJson).toList();
  }
}

Map<String, dynamic> buildAdminUsersQueryParameters({
  String? query,
  String? role,
  String? stationId,
  String? counterId,
  bool? isActive,
  String? ordering,
  int page = 1,
  int pageSize = 20,
}) {
  return _cleanQuery({
    'page': page < 1 ? 1 : page,
    'page_size': pageSize.clamp(1, 100),
    'q': query?.trim(),
    'role': role?.trim(),
    'station_id': stationId?.trim(),
    'counter_id': counterId?.trim(),
    if (isActive != null) 'is_active': isActive,
    'ordering': ordering?.trim(),
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

List<Map<String, dynamic>> _readResults(dynamic data) {
  if (data is List) {
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
  final map = _readMap(data);
  final results = map['results'];
  if (results is List) {
    return results.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
  throw ApiException(
      message: 'Réponse référentiel utilisateurs invalide.', details: data);
}

Map<String, dynamic> _readMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw ApiException(
      message: 'Réponse utilisateur interne invalide.', details: data);
}
