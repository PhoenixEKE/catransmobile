import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/booking/seat_hold_response.dart';
import 'package:catrans_app/models/booking/seat_map_response.dart';

class BookingApiService {
  final ApiClient _apiClient;

  BookingApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<SeatMapResponse> getSeatMap({
    required String departureId,
  }) async {
    final response = await _apiClient.get(
      'client/catalog/departures/$departureId/seat-map/',
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SeatMapResponse.fromJson(data);
    }

    if (data is Map) {
      return SeatMapResponse.fromJson(Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message: 'Réponse seat-map invalide.',
      details: data,
    );
  }

  Future<List<SeatHoldResponse>> createAutomaticSeatHold({
    required String departureId,
    required int passengersCount,
  }) {
    return _createSeatHold(
      data: {
        'departure_id': departureId,
        'passengers_count': passengersCount,
      },
    );
  }

  Future<List<SeatHoldResponse>> createManualSeatHold({
    required String departureId,
    required List<int> seatNumbers,
  }) {
    return _createSeatHold(
      data: {
        'departure_id': departureId,
        'seat_numbers': seatNumbers,
      },
    );
  }

  Future<List<SeatHoldResponse>> _createSeatHold({
    required Map<String, dynamic> data,
  }) async {
    final response = await _apiClient.post(
      'booking/seat-holds/',
      data: data,
    );

    final responseData = response.data;
    if (responseData is! List) {
      throw ApiException(
        message: 'Réponse de réservation temporaire invalide.',
        details: responseData,
      );
    }

    return responseData
        .map((item) => SeatHoldResponse.fromJson(_readObject(item)))
        .toList();
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Réponse de réservation temporaire invalide.',
      details: data,
    );
  }
}
