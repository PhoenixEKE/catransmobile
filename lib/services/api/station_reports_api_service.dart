import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/reports/station_cancellation_detail.dart';
import 'package:catrans_app/models/station/reports/station_reports_page.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change_detail.dart';

class StationReportsApiService {
  final ApiClient _apiClient;

  StationReportsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<StationReservationChangesPage> getReservationChanges({
    int page = 1,
    int pageSize = 25,
    String? status,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.get(
      'station/reservation-changes/',
      queryParameters: buildStationReportsQueryParameters(
        page: page,
        pageSize: pageSize,
        status: status,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationReservationChangesPage.fromJson(data);
    }
    if (data is Map) {
      return StationReservationChangesPage.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse liste reports gare invalide.',
      details: data,
    );
  }

  Future<StationReservationChangeDetail> getReservationChangeDetail(
    String changeId,
  ) async {
    final response = await _apiClient.get(
      'station/reservation-changes/$changeId/',
    );
    return _readReservationChangeDetail(response.data);
  }

  Future<StationReservationChangeDetail> approveReservationChange(
    String changeId,
  ) async {
    final response = await _apiClient.post(
      'station/reservation-changes/$changeId/approve/',
    );
    return _readReservationChangeActionResponse(response.data);
  }

  Future<StationReservationChangeDetail> rejectReservationChange(
    String changeId,
    String reason,
  ) async {
    final response = await _apiClient.post(
      'station/reservation-changes/$changeId/reject/',
      data: buildStationReportRejectPayload(reason),
    );
    return _readReservationChangeActionResponse(response.data);
  }

  Future<StationReservationChangeDetail> applyReservationChange(
    String changeId,
  ) async {
    final response = await _apiClient.post(
      'station/reservation-changes/$changeId/apply/',
    );
    return _readReservationChangeActionResponse(response.data);
  }

  Future<StationCancellationsPage> getCancellations({
    int page = 1,
    int pageSize = 25,
    String? status,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.get(
      'station/cancellations/',
      queryParameters: buildStationReportsQueryParameters(
        page: page,
        pageSize: pageSize,
        status: status,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationCancellationsPage.fromJson(data);
    }
    if (data is Map) {
      return StationCancellationsPage.fromJson(Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message: 'Réponse liste annulations gare invalide.',
      details: data,
    );
  }

  Future<StationCancellationDetail> getCancellationDetail(
    String cancellationId,
  ) async {
    final response =
        await _apiClient.get('station/cancellations/$cancellationId/');
    return _readCancellationDetail(response.data);
  }

  Future<StationCancellationDetail> approveCancellation(
    String cancellationId,
  ) async {
    final response = await _apiClient.post(
      'station/cancellations/$cancellationId/approve/',
    );
    return _readCancellationDetail(response.data);
  }

  Future<StationCancellationDetail> rejectCancellation(
    String cancellationId,
    String rejectionReason,
  ) async {
    final response = await _apiClient.post(
      'station/cancellations/$cancellationId/reject/',
      data: buildStationCancellationRejectPayload(rejectionReason),
    );
    return _readCancellationDetail(response.data);
  }

  Future<StationCancellationApplyResult> applyCancellation(
    String cancellationId,
  ) async {
    final response = await _apiClient.post(
      'station/cancellations/$cancellationId/apply/',
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationCancellationApplyResult.fromJson(data);
    }
    if (data is Map) {
      return StationCancellationApplyResult.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse application annulation invalide.',
      details: data,
    );
  }

  StationReservationChangeDetail _readReservationChangeActionResponse(
    dynamic data,
  ) {
    final map = _readMapOrThrow(
      data,
      'Réponse action report gare invalide.',
    );
    final change = map['change'];
    if (change is Map<String, dynamic>) {
      return StationReservationChangeDetail.fromJson(change);
    }
    if (change is Map) {
      return StationReservationChangeDetail.fromJson(
        Map<String, dynamic>.from(change),
      );
    }
    return StationReservationChangeDetail.fromJson(map);
  }

  StationReservationChangeDetail _readReservationChangeDetail(dynamic data) {
    return StationReservationChangeDetail.fromJson(
      _readMapOrThrow(data, 'Réponse détail report gare invalide.'),
    );
  }

  StationCancellationDetail _readCancellationDetail(dynamic data) {
    return StationCancellationDetail.fromJson(
      _readMapOrThrow(data, 'Réponse détail annulation gare invalide.'),
    );
  }

  Map<String, dynamic> _readMapOrThrow(dynamic data, String message) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(message: message, details: data);
  }
}

Map<String, dynamic> buildStationReportsQueryParameters({
  int page = 1,
  int pageSize = 25,
  String? status,
  String? search,
  DateTime? dateFrom,
  DateTime? dateTo,
}) {
  final safePage = page < 1 ? 1 : page;
  final safePageSize = pageSize.clamp(1, 100).toInt();
  final queryParameters = <String, dynamic>{
    'page': safePage,
    'page_size': safePageSize,
  };

  final normalizedStatus = status?.trim();
  if (normalizedStatus != null &&
      normalizedStatus.isNotEmpty &&
      normalizedStatus.toLowerCase() != 'all') {
    queryParameters['status'] = normalizedStatus;
  }

  final normalizedSearch = search?.trim();
  if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
    queryParameters['search'] = normalizedSearch;
  }

  if (dateFrom != null) {
    queryParameters['date_from'] = _formatDate(dateFrom);
  }
  if (dateTo != null) {
    queryParameters['date_to'] = _formatDate(dateTo);
  }

  return queryParameters;
}

Map<String, dynamic> buildStationReportRejectPayload(String reason) {
  final normalizedReason = reason.trim();
  if (normalizedReason.isEmpty) {
    throw ArgumentError.value(
        reason, 'reason', 'Le motif de rejet est requis.');
  }
  return {'reason': normalizedReason};
}

Map<String, dynamic> buildStationCancellationRejectPayload(
  String rejectionReason,
) {
  final normalizedReason = rejectionReason.trim();
  if (normalizedReason.isEmpty) {
    throw ArgumentError.value(
      rejectionReason,
      'rejectionReason',
      'Le motif de rejet est requis.',
    );
  }
  return {'rejection_reason': normalizedReason};
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
