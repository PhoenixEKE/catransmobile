import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/station_boarding_manifest.dart';
import 'package:catrans_app/models/station/station_boarding_summary.dart';
import 'package:catrans_app/models/station/station_departure.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';

class StationBoardingApiService {
  final ApiClient _apiClient;

  StationBoardingApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<StationDeparture>> getTodayDepartures({
    DateTime? date,
    String? stationId,
  }) async {
    const path = 'station/departures/today/';
    final queryParameters = {
      if (date != null) 'date': _formatDate(date),
      if (stationId != null && stationId.trim().isNotEmpty)
        'station_id': stationId.trim(),
    };

    if (kDebugMode) {
      debugPrint('[Boarding] getTodayDepartures start');
    }

    try {
      final response = await _apiClient.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (kDebugMode) {
        debugPrint(
          '[Boarding] getTodayDepartures response status=${response.statusCode}',
        );
      }

      final data = response.data;
      final departures = _readDepartureList(data);
      if (kDebugMode) {
        debugPrint(
          '[Boarding] getTodayDepartures parsed count=${departures.length}',
        );
      }

      return departures.map((item) => StationDeparture.fromJson(item)).toList();
    } on ApiException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Boarding] getTodayDepartures ApiException status=${error.statusCode}',
        );
      }
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[Boarding] getTodayDepartures errorType=${error.runtimeType}',
        );
      }
      rethrow;
    }
  }

  Future<StationDeparture> getDepartureDetail({
    required String departureId,
  }) async {
    final response = await _apiClient.get('station/departures/$departureId/');
    return StationDeparture.fromJson(_readObject(response.data));
  }

  Future<List<StationBoardingTicket>> getDeparturePassengers({
    required String departureId,
  }) async {
    final response = await _apiClient.get(
      'station/departures/$departureId/passengers/',
    );
    return _readPassengerList(response.data);
  }

  Future<List<StationBoardingTicket>> getDepartureTickets({
    required String departureId,
    String? status,
  }) async {
    final response = await _apiClient.get(
      'station/departures/$departureId/tickets/',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    return _readPassengerList(response.data);
  }

  Future<List<StationTicketValidation>> getDepartureValidations({
    required String departureId,
  }) async {
    final response = await _apiClient.get(
      'station/departures/$departureId/validations/',
    );

    final data = response.data;
    if (data is! List) {
      throw ApiException(
        message: 'Réponse validations embarquement invalide.',
        details: data,
      );
    }

    return data
        .map((item) => StationTicketValidation.fromJson(_readObject(item)))
        .toList();
  }

  Future<StationBoardingManifestResponse> getBoardingManifest({
    required String departureId,
  }) async {
    final response = await _apiClient.get(
      'station/departures/$departureId/boarding-manifest/',
    );
    return StationBoardingManifestResponse.fromJson(_readObject(response.data));
  }

  Future<StationBoardingSummaryResponse> getBoardingSummary({
    required String departureId,
  }) async {
    final response = await _apiClient.get(
      'station/departures/$departureId/boarding-summary/',
    );
    return StationBoardingSummaryResponse.fromJson(_readObject(response.data));
  }

  Future<StationTicketValidation> validateTicket({
    required String validationToken,
    required String departureId,
    String deviceIdentifier = 'staff_portal',
  }) async {
    final normalizedToken = validationToken.trim();
    if (normalizedToken.isEmpty) {
      throw ApiException(message: 'Le code du billet est obligatoire.');
    }

    return _validateTicket(
      identifier: {'validation_token': normalizedToken},
      departureId: departureId,
      deviceIdentifier: deviceIdentifier,
    );
  }

  Future<StationTicketValidation> validateTicketByReference({
    required String ticketReference,
    required String departureId,
    String deviceIdentifier = 'staff_portal',
  }) async {
    final normalizedReference = ticketReference.trim();
    if (normalizedReference.isEmpty) {
      throw ApiException(message: 'La référence du billet est obligatoire.');
    }

    return _validateTicket(
      identifier: {'ticket_reference': normalizedReference},
      departureId: departureId,
      deviceIdentifier: deviceIdentifier,
    );
  }

  Future<StationTicketValidation> _validateTicket({
    required Map<String, String> identifier,
    required String departureId,
    required String deviceIdentifier,
  }) async {
    final normalizedDepartureId = departureId.trim();
    if (normalizedDepartureId.isEmpty) {
      throw ApiException(message: 'Le départ sélectionné est obligatoire.');
    }

    final response = await _apiClient.post(
      'tickets/validate/',
      data: {
        ...identifier,
        'departure_id': normalizedDepartureId,
        if (deviceIdentifier.trim().isNotEmpty)
          'device_identifier': deviceIdentifier.trim(),
      },
    );

    return StationTicketValidation.fromJson(_readObject(response.data));
  }

  List<Map<String, dynamic>> _readDepartureList(dynamic data) {
    if (data is List) {
      return data.map(_readObject).toList();
    }

    if (data is Map) {
      final object = Map<String, dynamic>.from(data);
      final results = object['results'];
      if (results is List) return results.map(_readObject).toList();

      final departures = object['departures'];
      if (departures is List) return departures.map(_readObject).toList();
    }

    throw ApiException(
      message: 'Réponse départs du jour invalide.',
      details: data,
    );
  }

  List<StationBoardingTicket> _readPassengerList(dynamic data) {
    if (data is! List) {
      throw ApiException(
        message: 'Réponse passagers embarquement invalide.',
        details: data,
      );
    }

    return data
        .map((item) => StationBoardingTicket.fromJson(_readObject(item)))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Réponse embarquement invalide.',
      details: data,
    );
  }
}
