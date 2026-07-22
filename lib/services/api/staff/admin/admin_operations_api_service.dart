import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/operations/seat_layout_seat.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_seat_class_zone_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';

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

  Future<PagedResult<SeatLayoutSeat>> listSeatLayoutSeats(
    String seatLayoutId, {
    String? query,
    String? seatType,
    bool? isActive,
    bool? isSelectable,
    String? ordering,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _apiClient.get(
      'admin/operations/seat-layouts/$seatLayoutId/seats/',
      queryParameters: buildAdminOperationsQueryParameters(
        query: query,
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: {
          'seat_type': seatType?.trim(),
          'is_selectable': isSelectable,
        },
      ),
    );
    return PagedResult.fromJson(response.data, SeatLayoutSeat.fromJson);
  }

  Future<SeatLayoutSeat> getSeatLayoutSeat(
    String seatLayoutId,
    String seatId,
  ) async {
    final response = await _apiClient.get(
      'admin/operations/seat-layouts/$seatLayoutId/seats/$seatId/',
    );
    return SeatLayoutSeat.fromJson(_readMap(response.data));
  }

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

  Future<PagedResult<AdminSeatClassZone>> listSeatClassZones(
    String templateId, {
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _apiClient.get(
      'admin/operations/departure-templates/$templateId/seat-class-zones/',
      queryParameters: buildAdminOperationsQueryParameters(
        isActive: isActive,
        ordering: ordering,
        page: page,
        pageSize: pageSize,
      ),
    );
    return PagedResult.fromJson(response.data, AdminSeatClassZone.fromJson);
  }

  Future<List<AdminSeatClassZone>> replaceSeatClassZones(
    String templateId,
    List<AdminSeatClassZoneDraft> zones,
  ) async {
    final response = await _apiClient.post(
      'admin/operations/departure-templates/$templateId/seat-class-zones/replace/',
      data: AdminSeatClassZoneReplaceRequest(zones: zones).toJson(),
    );
    return PagedResult.fromJson(response.data, AdminSeatClassZone.fromJson)
        .results;
  }

  Future<PagedResult<AdminOperationRecord>> listDepartures({
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTemplateId,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) =>
      _list(
        'admin/operations/departures/',
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: {
          'station_id': stationId?.trim(),
          'route_id': routeId?.trim(),
          'service_class_id': serviceClassId?.trim(),
          'departure_template_id': departureTemplateId?.trim(),
          'status': status?.trim(),
          'date_from': dateFrom?.trim(),
          'date_to': dateTo?.trim(),
        },
      );

  Future<PagedResult<AdminDeparture>> listAdminDepartures({
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTemplateId,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      'admin/operations/departures/',
      queryParameters: buildAdminOperationsQueryParameters(
        ordering: ordering,
        page: page,
        pageSize: pageSize,
        extra: {
          'station_id': stationId?.trim(),
          'route_id': routeId?.trim(),
          'service_class_id': serviceClassId?.trim(),
          'departure_template_id': departureTemplateId?.trim(),
          'status': status?.trim(),
          'date_from': dateFrom?.trim(),
          'date_to': dateTo?.trim(),
        },
      ),
    );
    return PagedResult.fromJson(response.data, AdminDeparture.fromJson);
  }

  Future<AdminOperationRecord> getDeparture(String id) =>
      _get('admin/operations/departures/$id/');

  Future<AdminDeparture> getAdminDeparture(String id) async {
    final response = await _apiClient.get('admin/operations/departures/$id/');
    return AdminDeparture.fromJson(_readMap(response.data));
  }

  Future<AdminDepartureCreateResult> createAdminDeparture(
    AdminDepartureCreateRequest request,
  ) async {
    final response = await _apiClient.post(
      'admin/operations/departures/',
      data: request.toJson(),
    );
    return AdminDepartureCreateResult.fromJson(_readMap(response.data));
  }

  Future<AdminDeparture> updateAdminDepartureDate(
    String departureId,
    AdminDepartureDateUpdateRequest request,
  ) async {
    final response = await _apiClient.patch(
      'admin/operations/departures/$departureId/',
      data: request.toJson(),
    );
    return AdminDeparture.fromJson(_readMap(response.data));
  }

  Future<Map<String, dynamic>> getDepartureSeatMap(String departureId) async {
    final response = await _apiClient
        .get('admin/operations/departures/$departureId/seat-map/');
    return _readMap(response.data);
  }

  Future<AdminDepartureSeatMap> getAdminDepartureSeatMap(
    String departureId,
  ) async {
    final response = await _apiClient
        .get('admin/operations/departures/$departureId/seat-map/');
    return AdminDepartureSeatMap.fromJson(_readMap(response.data));
  }

  Future<AdminDepartureSeatsResponse> listDepartureSeats({
    required String departureId,
    String? status,
    String? seatType,
    int? seatNumber,
    bool? isSelectable,
    String? ordering,
  }) async {
    final response = await _apiClient.get(
      'admin/operations/departures/$departureId/seats/',
      queryParameters: buildAdminOperationsQueryParameters(
        ordering: ordering,
        page: 1,
        pageSize: 100,
        extra: {
          'status': status?.trim(),
          'seat_type': seatType?.trim(),
          'seat_number': seatNumber,
          'is_selectable': isSelectable,
        },
      )..removeWhere((key, value) => key == 'page' || key == 'page_size'),
    );
    return AdminDepartureSeatsResponse.fromJson(_readMap(response.data));
  }

  Future<Map<String, dynamic>> previewDepartures(
    String templateId,
    AdminDepartureDatesRequest request,
  ) async {
    final response = await _apiClient.post(
      'admin/operations/departure-templates/$templateId/departures/preview/',
      data: request.toJson(),
    );
    return _readMap(response.data);
  }

  Future<AdminDepartureGenerationResult> generateDepartures(
    String templateId,
    AdminDepartureDatesRequest request,
  ) async {
    final response = await _apiClient.post(
      'admin/operations/departure-templates/$templateId/departures/generate/',
      data: request.toJson(),
    );
    return AdminDepartureGenerationResult.fromJson(_readMap(response.data));
  }

  Future<AdminDepartureSeatGenerationResult> generateSeats(
    String departureId,
  ) async {
    final response = await _apiClient
        .post('admin/operations/departures/$departureId/generate-seats/');
    return AdminDepartureSeatGenerationResult.fromJson(_readMap(response.data));
  }

  Future<AdminOperationActionResponse> blockSeats(
    String departureId,
    List<int> seatNumbers, {
    required String reason,
  }) async {
    final response = await _apiClient.post(
      'admin/operations/departures/$departureId/seats/block/',
      data: AdminDepartureSeatActionRequest(
        seatNumbers: seatNumbers,
        reason: reason,
      ).toJson(),
    );
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<AdminOperationActionResponse> unblockSeats(
    String departureId,
    List<int> seatNumbers, {
    required String reason,
  }) async {
    final response = await _apiClient.post(
      'admin/operations/departures/$departureId/seats/unblock/',
      data: AdminDepartureSeatActionRequest(
        seatNumbers: seatNumbers,
        reason: reason,
      ).toJson(),
    );
    return AdminOperationActionResponse.fromJson(_readMap(response.data));
  }

  Future<AdminDepartureActionResponse> openDeparture(String departureId) =>
      _departureAction(departureId, 'open');

  Future<AdminDepartureActionResponse> closeDeparture(String departureId) =>
      _departureAction(departureId, 'close');

  Future<AdminDepartureActionResponse> markDeparted(String departureId) =>
      _departureAction(departureId, 'depart');

  Future<AdminDepartureActionResponse> cancelDeparture(String departureId) =>
      _departureAction(departureId, 'cancel');

  Future<StationTicketValidation> validateTicket({
    required String validationToken,
    required String departureId,
    String deviceIdentifier = 'admin_operations_portal',
  }) async {
    final response = await _apiClient.post(
      'tickets/validate/',
      data: {
        'validation_token': validationToken.trim(),
        'departure_id': departureId.trim(),
        if (deviceIdentifier.trim().isNotEmpty)
          'device_identifier': deviceIdentifier.trim(),
      },
    );
    return StationTicketValidation.fromJson(_readMap(response.data));
  }

  Future<StationTicketValidation> validateTicketByReference({
    required String ticketReference,
    required String departureId,
    String deviceIdentifier = 'admin_operations_portal',
  }) async {
    final response = await _apiClient.post(
      'tickets/validate/',
      data: {
        'ticket_reference': ticketReference.trim(),
        'departure_id': departureId.trim(),
        if (deviceIdentifier.trim().isNotEmpty)
          'device_identifier': deviceIdentifier.trim(),
      },
    );
    return StationTicketValidation.fromJson(_readMap(response.data));
  }

  Future<AdminDepartureActionResponse> _departureAction(
    String departureId,
    String action,
  ) async {
    final response = await _apiClient
        .post('admin/operations/departures/$departureId/$action/');
    return AdminDepartureActionResponse.fromJson(_readMap(response.data));
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
