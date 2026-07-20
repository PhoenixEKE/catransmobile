import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/station_reservation_detail.dart';
import 'package:catrans_app/models/station/station_reservation_list.dart';
import 'package:catrans_app/models/station/station_search_result.dart';
import 'package:catrans_app/models/station/station_ticket_summary.dart';
import 'package:catrans_app/models/staff/admin/station_cash_models.dart';

class StationCounterApiService {
  final ApiClient _apiClient;

  StationCounterApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<StationReservationListResponse> listReservations({
    String? query,
    String? status,
    String? paymentStatus,
    String? ticketStatus,
    String? dateFrom,
    String? dateTo,
    String? serviceClass,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };

    void addIfPresent(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        queryParameters[key] = normalized;
      }
    }

    addIfPresent('q', query);
    addIfPresent('status', status);
    addIfPresent('payment_status', paymentStatus);
    addIfPresent('ticket_status', ticketStatus);
    addIfPresent('date_from', dateFrom);
    addIfPresent('date_to', dateTo);
    addIfPresent('service_class', serviceClass);

    final response = await _apiClient.get(
      'station/reservations/',
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationReservationListResponse.fromJson(data);
    }
    if (data is Map) {
      return StationReservationListResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse liste réservations gare invalide.',
      details: data,
    );
  }

  Future<StationSearchResponse> searchReservations({
    required String query,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      throw ApiException(message: 'Entrez au moins 2 caractères.');
    }

    final response = await _apiClient.get(
      'station/search/',
      queryParameters: {'q': trimmedQuery},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationSearchResponse.fromJson(data);
    }
    if (data is Map) {
      return StationSearchResponse.fromJson(Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message: 'Réponse de recherche guichet invalide.',
      details: data,
    );
  }

  Future<StationReservationDetail> getReservationDetail({
    required String reservationId,
  }) async {
    final response = await _apiClient.get(
      'station/reservations/$reservationId/',
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationReservationDetail.fromJson(data);
    }
    if (data is Map) {
      return StationReservationDetail.fromJson(Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message: 'Réponse détail réservation invalide.',
      details: data,
    );
  }

  Future<StationTicketPrintResponse> getTicketPrintInfo({
    required String ticketId,
  }) async {
    final response = await _apiClient.get('station/tickets/$ticketId/print/');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationTicketPrintResponse.fromJson(data);
    }
    if (data is Map) {
      return StationTicketPrintResponse.fromJson(
          Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message: 'Réponse impression ticket invalide.',
      details: data,
    );
  }

  Future<Uint8List> downloadTicketPdfBytes({
    required String ticketId,
  }) async {
    final response = await _apiClient.get(
      'station/tickets/$ticketId/pdf/',
      options: Options(responseType: ResponseType.bytes),
    );

    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    throw ApiException(
      message: 'Réponse PDF ticket invalide.',
      details: data,
    );
  }

  Future<StationCashSaleCreateResponse> createCashReservation(
    StationCashSaleCreateRequest request,
  ) async {
    final response = await _apiClient.post(
      'station/reservations/',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationCashSaleCreateResponse.fromJson(data);
    }
    if (data is Map) {
      return StationCashSaleCreateResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse création vente cash invalide.',
      details: data,
    );
  }

  Future<StationCashConfirmResponse> confirmCashPayment(
    String reservationId, {
    String? note,
  }) async {
    final response = await _apiClient.post(
      'station/reservations/$reservationId/confirm-cash/',
      data: {
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return StationCashConfirmResponse.fromJson(data);
    }
    if (data is Map) {
      return StationCashConfirmResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw ApiException(
      message: 'Réponse confirmation cash invalide.',
      details: data,
    );
  }
}
