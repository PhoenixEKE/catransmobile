import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/paged_result.dart';

abstract class AdminTransportBaseApiTransport {
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<dynamic> post(String path, {dynamic data});

  Future<dynamic> patch(String path, {dynamic data});
}

class ApiClientAdminTransportBaseApiTransport
    implements AdminTransportBaseApiTransport {
  final ApiClient _apiClient;

  ApiClientAdminTransportBaseApiTransport(this._apiClient);

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _apiClient.get(
      path,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  @override
  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await _apiClient.post(path, data: data);
    return response.data;
  }

  @override
  Future<dynamic> patch(String path, {dynamic data}) async {
    final response = await _apiClient.patch(path, data: data);
    return response.data;
  }
}

class AdminTransportBaseApiService {
  final AdminTransportBaseApiTransport _transport;

  AdminTransportBaseApiService({
    ApiClient? apiClient,
    AdminTransportBaseApiTransport? transport,
  }) : _transport = transport ??
            ApiClientAdminTransportBaseApiTransport(apiClient ?? ApiClient());

  Future<PagedResult<AdminCompany>> listCompanies({
    String? query,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/companies/',
      AdminCompany.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<AdminCompany> getCompany(String id) {
    return _get('admin/transport/companies/$id/', AdminCompany.fromJson);
  }

  Future<AdminCompany> createCompany(AdminCompanyCreateRequest request) {
    return _create(
      'admin/transport/companies/',
      request.toJson(),
      AdminCompany.fromJson,
    );
  }

  Future<AdminCompany> updateCompany(
    String id,
    AdminCompanyUpdateRequest request,
  ) {
    return _patch(
      'admin/transport/companies/$id/',
      request.toJson(),
      AdminCompany.fromJson,
    );
  }

  Future<AdminCompany> activateCompany(String id) {
    return _action(
        'admin/transport/companies/$id/activate/', AdminCompany.fromJson);
  }

  Future<AdminCompany> deactivateCompany(String id) {
    return _action(
      'admin/transport/companies/$id/deactivate/',
      AdminCompany.fromJson,
    );
  }

  Future<PagedResult<AdminCity>> listCities({
    String? query,
    String? country,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/cities/',
      AdminCity.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {'country': country?.trim()},
    );
  }

  Future<AdminCity> getCity(String id) {
    return _get('admin/transport/cities/$id/', AdminCity.fromJson);
  }

  Future<AdminCity> createCity(AdminCityCreateRequest request) {
    return _create(
      'admin/transport/cities/',
      request.toJson(),
      AdminCity.fromJson,
    );
  }

  Future<AdminCity> updateCity(String id, AdminCityUpdateRequest request) {
    return _patch(
      'admin/transport/cities/$id/',
      request.toJson(),
      AdminCity.fromJson,
    );
  }

  Future<AdminCity> activateCity(String id) {
    return _action('admin/transport/cities/$id/activate/', AdminCity.fromJson);
  }

  Future<AdminCity> deactivateCity(String id) {
    return _action(
      'admin/transport/cities/$id/deactivate/',
      AdminCity.fromJson,
    );
  }

  Future<PagedResult<AdminStation>> listStations({
    String? query,
    String? companyId,
    String? cityId,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/stations/',
      AdminStation.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {
        'company_id': companyId?.trim(),
        'city_id': cityId?.trim(),
      },
    );
  }

  Future<AdminStation> getStation(String id) {
    return _get('admin/transport/stations/$id/', AdminStation.fromJson);
  }

  Future<AdminStation> createStation(AdminStationCreateRequest request) {
    return _create(
      'admin/transport/stations/',
      request.toJson(),
      AdminStation.fromJson,
    );
  }

  Future<AdminStation> updateStation(
    String id,
    AdminStationUpdateRequest request,
  ) {
    return _patch(
      'admin/transport/stations/$id/',
      request.toJson(),
      AdminStation.fromJson,
    );
  }

  Future<AdminStation> activateStation(String id) {
    return _action(
        'admin/transport/stations/$id/activate/', AdminStation.fromJson);
  }

  Future<AdminStation> deactivateStation(String id) {
    return _action(
      'admin/transport/stations/$id/deactivate/',
      AdminStation.fromJson,
    );
  }

  Future<(AdminStation, String?)> deactivateStationCascade(String id) {
    return _actionCascade(
      'admin/transport/stations/$id/deactivate/',
      AdminStation.fromJson,
      cascade: true,
    );
  }

  Future<PagedResult<AdminStationCounter>> listCounters({
    required String stationId,
    String? query,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/stations/${stationId.trim()}/counters/',
      AdminStationCounter.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<AdminStationCounter> getCounter(String counterId) {
    return _get(
      'admin/transport/counters/$counterId/',
      AdminStationCounter.fromJson,
    );
  }

  Future<AdminStationCounter> createCounter({
    required String stationId,
    required AdminStationCounterCreateRequest request,
  }) {
    return _create(
      'admin/transport/stations/${stationId.trim()}/counters/',
      request.toJson(),
      AdminStationCounter.fromJson,
    );
  }

  Future<AdminStationCounter> updateCounter(
    String counterId,
    AdminStationCounterUpdateRequest request,
  ) {
    return _patch(
      'admin/transport/counters/$counterId/',
      request.toJson(),
      AdminStationCounter.fromJson,
    );
  }

  Future<AdminStationCounter> activateCounter(String counterId) {
    return _action(
      'admin/transport/counters/$counterId/activate/',
      AdminStationCounter.fromJson,
    );
  }

  Future<AdminStationCounter> deactivateCounter(String counterId) {
    return _action(
      'admin/transport/counters/$counterId/deactivate/',
      AdminStationCounter.fromJson,
    );
  }

  Future<PagedResult<AdminServiceClass>> listServiceClasses({
    String? query,
    bool? allowsSeatSelection,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/service-classes/',
      AdminServiceClass.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {'allows_seat_selection': allowsSeatSelection},
    );
  }

  Future<AdminServiceClass> getServiceClass(String id) {
    return _get(
      'admin/transport/service-classes/$id/',
      AdminServiceClass.fromJson,
    );
  }

  Future<AdminServiceClass> createServiceClass(
    AdminServiceClassCreateRequest request,
  ) {
    return _create(
      'admin/transport/service-classes/',
      request.toJson(),
      AdminServiceClass.fromJson,
    );
  }

  Future<AdminServiceClass> updateServiceClass(
    String id,
    AdminServiceClassUpdateRequest request,
  ) {
    return _patch(
      'admin/transport/service-classes/$id/',
      request.toJson(),
      AdminServiceClass.fromJson,
    );
  }

  Future<AdminServiceClass> activateServiceClass(String id) {
    return _action(
      'admin/transport/service-classes/$id/activate/',
      AdminServiceClass.fromJson,
    );
  }

  Future<AdminServiceClass> deactivateServiceClass(String id) {
    return _action(
      'admin/transport/service-classes/$id/deactivate/',
      AdminServiceClass.fromJson,
    );
  }

  Future<(AdminServiceClass, String?)> deactivateServiceClassCascade(
    String id,
  ) {
    return _actionCascade(
      'admin/transport/service-classes/$id/deactivate/',
      AdminServiceClass.fromJson,
      cascade: true,
    );
  }

  Future<PagedResult<AdminRoute>> listRoutes({
    String? query,
    String? companyId,
    String? departureStationId,
    String? departureCityId,
    String? destinationCityId,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/routes/',
      AdminRoute.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {
        'company_id': companyId?.trim(),
        'departure_station_id': departureStationId?.trim(),
        'departure_city_id': departureCityId?.trim(),
        'destination_city_id': destinationCityId?.trim(),
      },
    );
  }

  Future<AdminRoute> getRoute(String id) {
    return _get('admin/transport/routes/$id/', AdminRoute.fromJson);
  }

  Future<AdminRoute> createRoute(AdminRouteCreateRequest request) {
    return _create(
        'admin/transport/routes/', request.toJson(), AdminRoute.fromJson);
  }

  Future<AdminRoute> updateRoute(String id, AdminRouteUpdateRequest request) {
    return _patch(
        'admin/transport/routes/$id/', request.toJson(), AdminRoute.fromJson);
  }

  Future<AdminRoute> activateRoute(String id) {
    return _action('admin/transport/routes/$id/activate/', AdminRoute.fromJson);
  }

  Future<AdminRoute> deactivateRoute(String id) {
    return _action(
        'admin/transport/routes/$id/deactivate/', AdminRoute.fromJson);
  }

  Future<(AdminRoute, String?)> deactivateRouteCascade(String id) {
    return _actionCascade(
      'admin/transport/routes/$id/deactivate/',
      AdminRoute.fromJson,
      cascade: true,
    );
  }

  Future<PagedResult<AdminFare>> listFares({
    String? query,
    String? routeId,
    String? serviceClassId,
    String? currency,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/fares/',
      AdminFare.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {
        'route_id': routeId?.trim(),
        'service_class_id': serviceClassId?.trim(),
        'currency': currency?.trim().toUpperCase(),
      },
    );
  }

  Future<AdminFare> getFare(String id) {
    return _get('admin/transport/fares/$id/', AdminFare.fromJson);
  }

  Future<AdminFare> createFare(AdminFareCreateRequest request) {
    return _create(
        'admin/transport/fares/', request.toJson(), AdminFare.fromJson);
  }

  Future<AdminFare> updateFare(String id, AdminFarePatchRequest request) {
    return _patch(
        'admin/transport/fares/$id/', request.toJson(), AdminFare.fromJson);
  }

  Future<AdminFare> replaceFare(String id, AdminFareReplaceRequest request) {
    return _create('admin/transport/fares/$id/replace/', request.toJson(),
        AdminFare.fromJson);
  }

  Future<AdminFare> activateFare(String id) {
    return _action('admin/transport/fares/$id/activate/', AdminFare.fromJson);
  }

  Future<AdminFare> deactivateFare(String id) {
    return _action('admin/transport/fares/$id/deactivate/', AdminFare.fromJson);
  }

  Future<PagedResult<AdminSchedule>> listSchedules({
    String? query,
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTime,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) {
    return _list(
      'admin/transport/schedules/',
      AdminSchedule.fromJson,
      query: query,
      isActive: isActive,
      ordering: ordering,
      page: page,
      pageSize: pageSize,
      extra: {
        'station_id': stationId?.trim(),
        'route_id': routeId?.trim(),
        'service_class_id': serviceClassId?.trim(),
        'departure_time': departureTime?.trim(),
      },
    );
  }

  Future<AdminSchedule> getSchedule(String id) {
    return _get('admin/transport/schedules/$id/', AdminSchedule.fromJson);
  }

  Future<AdminSchedule> createSchedule(AdminScheduleCreateRequest request) {
    return _create(
      'admin/transport/schedules/',
      request.toJson(),
      AdminSchedule.fromJson,
    );
  }

  Future<AdminSchedule> updateSchedule(
    String id,
    AdminScheduleUpdateRequest request,
  ) {
    return _patch(
      'admin/transport/schedules/$id/',
      request.toJson(),
      AdminSchedule.fromJson,
    );
  }

  Future<AdminSchedule> activateSchedule(String id) {
    return _action(
      'admin/transport/schedules/$id/activate/',
      AdminSchedule.fromJson,
    );
  }

  Future<AdminSchedule> deactivateSchedule(String id) {
    return _action(
      'admin/transport/schedules/$id/deactivate/',
      AdminSchedule.fromJson,
    );
  }


  Future<PagedResult<T>> _list<T>(
    String path,
    T Function(AdminTransportJson json) fromJson, {
    String? query,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = await _transport.get(
      path,
      queryParameters: buildAdminTransportBaseQueryParameters(
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: extra,
      ),
    );
    return PagedResult.fromJson(data, fromJson);
  }

  Future<T> _get<T>(
    String path,
    T Function(AdminTransportJson json) fromJson,
  ) async {
    final data = await _transport.get(path);
    return fromJson(_readMap(data));
  }

  Future<T> _create<T>(
    String path,
    AdminTransportJson body,
    T Function(AdminTransportJson json) fromJson,
  ) async {
    final data = await _transport.post(path, data: body);
    return fromJson(_readMap(data));
  }

  Future<T> _patch<T>(
    String path,
    AdminTransportJson body,
    T Function(AdminTransportJson json) fromJson,
  ) async {
    final data = await _transport.patch(path, data: body);
    return fromJson(_readMap(data));
  }

  Future<T> _action<T>(
    String path,
    T Function(AdminTransportJson json) fromJson,
  ) async {
    final data = await _transport.post(path);
    final map = _readMap(data);
    return fromJson(_readMap(map['object'] ?? map));
  }

  /// Same as [_action] but also returns the informative message the backend
  /// sends back when a cascade deactivation actually deactivated/closed
  /// dependent records.
  Future<(T, String?)> _actionCascade<T>(
    String path,
    T Function(AdminTransportJson json) fromJson, {
    required bool cascade,
  }) async {
    final data = await _transport.post(
      path,
      data: {'cascade': cascade},
    );
    final map = _readMap(data);
    final object = fromJson(_readMap(map['object'] ?? map));
    return (object, map['message'] as String?);
  }
}

Map<String, dynamic> buildAdminTransportBaseQueryParameters({
  String? query,
  bool? isActive,
  String? ordering,
  int? page,
  int? pageSize,
  Map<String, dynamic> extra = const {},
}) {
  return _cleanQuery({
    if (page != null) 'page': page < 1 ? 1 : page,
    if (pageSize != null) 'page_size': pageSize.clamp(1, 100),
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
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    result[entry.key] = value;
  }
  return result;
}

AdminTransportJson _readMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return AdminTransportJson.from(data);
  }
  throw ApiException(
    message: 'Réponse référentiel transport invalide.',
    details: data,
  );
}
