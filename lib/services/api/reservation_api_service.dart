import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/reservation/create_economy_reservation_request.dart';
import 'package:catrans_app/models/reservation/create_prestige_reservation_request.dart';
import 'package:catrans_app/models/reservation/pending_reservation_response.dart';
import 'package:catrans_app/models/reservation/reservation_create_item.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';

class ReservationApiService {
  final ApiClient _apiClient;

  ReservationApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<ReservationDetail> createEconomyPendingReservation({
    required String departureId,
    String serviceClassCode = 'ECONOMIE',
    required List<ReservationCreateItem> items,
  }) async {
    if (items.isEmpty) {
      throw ApiException(
        message: 'La reservation doit contenir au moins un voyageur.',
      );
    }

    final request = CreateEconomyReservationRequest(
      departureId: departureId,
      serviceClassCode: serviceClassCode,
      items: items,
    );

    final response = await _apiClient.post(
      'booking/reservations/',
      data: request.toJson(),
    );

    return ReservationDetail.fromJson(_readObject(response.data));
  }

  Future<ReservationDetail> createPrestigePendingReservation({
    required List<ReservationCreateItem> items,
  }) async {
    if (items.isEmpty) {
      throw ApiException(
        message: 'La reservation doit contenir au moins un voyageur.',
      );
    }

    final missingHold = items.any(
      (item) => item.seatHoldId == null || item.seatHoldId!.trim().isEmpty,
    );
    if (missingHold) {
      throw ApiException(
        message: 'Chaque voyageur Prestige doit avoir un hold de siege.',
      );
    }

    final request = CreatePrestigeReservationRequest(items: items);

    final response = await _apiClient.post(
      'booking/reservations/',
      data: request.toJson(),
    );

    return ReservationDetail.fromJson(_readObject(response.data));
  }

  Future<ReservationDetail> getReservationDetail({
    required String reservationId,
  }) async {
    final response = await _apiClient.get(
      'booking/reservations/$reservationId/',
    );

    return ReservationDetail.fromJson(_readObject(response.data));
  }

  Future<PendingReservationResponse> getCurrentPendingReservation() async {
    final response = await _apiClient.get(
      'booking/reservations/pending/current/',
    );

    return PendingReservationResponse.fromJson(_readObject(response.data));
  }

  Future<ReservationDetail> cancelReservation({
    required String reservationId,
  }) async {
    final response = await _apiClient.post(
      'booking/reservations/$reservationId/cancel/',
      data: const <String, dynamic>{},
    );

    return ReservationDetail.fromJson(_readObject(response.data));
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Reponse reservation invalide.',
      details: data,
    );
  }
}
