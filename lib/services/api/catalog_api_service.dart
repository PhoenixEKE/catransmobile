import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/catalog/catalog_departure_list_response.dart';
import 'package:catrans_app/models/catalog/catalog_destination.dart';
import 'package:catrans_app/models/catalog/catalog_station.dart';
import 'package:catrans_app/models/catalog/catalog_travel_date.dart';

class CatalogApiService {
  final ApiClient _apiClient;

  CatalogApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<List<CatalogStation>> getStations() async {
    final response = await _apiClient.get('client/catalog/stations/');
    final results = _readResults(response.data);

    return results
        .map((item) => CatalogStation.fromJson(_readObject(item)))
        .toList();
  }

  Future<List<CatalogDestination>> getDestinations({
    required String stationId,
  }) async {
    final response = await _apiClient.get(
      'client/catalog/destinations/',
      queryParameters: {'station_id': stationId},
    );
    final results = _readResults(response.data);

    return results
        .map((item) => CatalogDestination.fromJson(_readObject(item)))
        .toList();
  }

  Future<List<CatalogTravelDate>> getDates({
    required String stationId,
    required String destinationCityId,
  }) async {
    final response = await _apiClient.get(
      'client/catalog/dates/',
      queryParameters: {
        'station_id': stationId,
        'destination_city_id': destinationCityId,
      },
    );
    final results = _readResults(response.data);

    return results
        .map((item) => CatalogTravelDate.fromJson(_readObject(item)))
        .toList();
  }

  Future<CatalogDepartureListResponse> getDepartures({
    required String stationId,
    required String destinationCityId,
    required DateTime date,
    int? limit,
  }) async {
    final response = await _apiClient.get(
      'client/catalog/departures/',
      queryParameters: {
        'station_id': stationId,
        'destination_city_id': destinationCityId,
        'date': _formatDate(date),
        if (limit != null) 'limit': limit,
      },
    );

    return CatalogDepartureListResponse.fromJson(_readEnvelope(response.data));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> _readEnvelope(dynamic data) {
    final object = _readObject(data);
    if (object['results'] is List) {
      return object;
    }

    throw ApiException(
      message: 'Réponse catalogue invalide.',
      details: data,
    );
  }

  List<dynamic> _readResults(dynamic data) {
    final object = _readEnvelope(data);
    return object['results'] as List<dynamic>;
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw ApiException(
      message: 'Réponse catalogue invalide.',
      details: data,
    );
  }
}
