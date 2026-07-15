import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/trip/client_trip_list_response.dart';

class TripApiService {
  final ApiClient _apiClient;

  TripApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ClientTripListResponse> getTrips() async {
    final response = await _apiClient.get('client/trips/');
    return ClientTripListResponse.fromJson(_readObject(response.data));
  }

  Future<ClientTripListResponse> getUpcomingTrips() async {
    final response = await _apiClient.get('client/trips/upcoming/');
    return ClientTripListResponse.fromJson(_readObject(response.data));
  }

  Future<ClientTripListResponse> getHistoryTrips() async {
    final response = await _apiClient.get('client/trips/history/');
    return ClientTripListResponse.fromJson(_readObject(response.data));
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Reponse voyages invalide.',
      details: data,
    );
  }
}
