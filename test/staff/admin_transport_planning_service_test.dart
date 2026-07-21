import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  test('uses route filters and endpoints', () async {
    final fake = _FakeTransport({
      _key('GET', 'admin/transport/routes/'): _paged([_routeJson()])
    });
    final service = AdminTransportBaseApiService(transport: fake);

    await service.listRoutes(
        companyId: 'company-1',
        departureStationId: 'station-1',
        destinationCityId: 'city-2',
        ordering: 'destination_name_snapshot');

    expect(fake.requests.single.path, 'admin/transport/routes/');
    expect(fake.requests.single.queryParameters, {
      'ordering': 'destination_name_snapshot',
      'company_id': 'company-1',
      'departure_station_id': 'station-1',
      'destination_city_id': 'city-2',
    });
  });

  test('creates route without is_active or unknown fields', () async {
    final fake =
        _FakeTransport({_key('POST', 'admin/transport/routes/'): _routeJson()});
    final service = AdminTransportBaseApiService(transport: fake);

    await service.createRoute(const AdminRouteCreateRequest(
        companyId: 'company-1',
        departureStationId: 'station-1',
        destinationName: 'Korhogo'));

    expect(fake.requests.single.body, {
      'company_id': 'company-1',
      'departure_station_id': 'station-1',
      'destination_name': 'Korhogo',
    });
  });

  test('uses fare replace endpoint and never patch amount', () async {
    final fake = _FakeTransport(
        {_key('POST', 'admin/transport/fares/fare-1/replace/'): _fareJson()});
    final service = AdminTransportBaseApiService(transport: fake);

    await service.replaceFare(
        'fare-1', const AdminFareReplaceRequest(amount: '8000.00'));

    expect(fake.requests.single.method, 'POST');
    expect(fake.requests.single.path, 'admin/transport/fares/fare-1/replace/');
    expect(fake.requests.single.body, {'amount': '8000.00', 'currency': 'XOF'});
    expect(
        fake.requests.any((request) =>
            request.method == 'PATCH' && request.body.containsKey('amount')),
        isFalse);
  });

  test('creates fare with typed payload', () async {
    final fake =
        _FakeTransport({_key('POST', 'admin/transport/fares/'): _fareJson()});
    final service = AdminTransportBaseApiService(transport: fake);

    await service.createFare(const AdminFareCreateRequest(
        routeId: 'route-1', serviceClassId: 'class-1', amount: '7000.00'));

    expect(fake.requests.single.body, {
      'route_id': 'route-1',
      'service_class_id': 'class-1',
      'amount': '7000.00',
      'currency': 'XOF',
    });
  });
}

class _FakeTransport implements AdminTransportBaseApiTransport {
  final Map<String, dynamic> responses;
  final List<_Request> requests = [];
  _FakeTransport(this.responses);

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    requests.add(
        _Request('GET', path, queryParameters: queryParameters ?? const {}));
    return _responseFor('GET', path);
  }

  @override
  Future<dynamic> post(String path, {dynamic data}) async {
    requests.add(_Request('POST', path,
        body: data as Map<String, dynamic>? ?? const {}));
    return _responseFor('POST', path);
  }

  @override
  Future<dynamic> patch(String path, {dynamic data}) async {
    requests.add(_Request('PATCH', path,
        body: data as Map<String, dynamic>? ?? const {}));
    return _responseFor('PATCH', path);
  }

  dynamic _responseFor(String method, String path) {
    final key = _key(method, path);
    if (!responses.containsKey(key)) {
      throw StateError('Unexpected API call: $key');
    }
    return responses[key];
  }
}

class _Request {
  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> body;
  const _Request(this.method, this.path,
      {this.queryParameters = const {}, this.body = const {}});
}

String _key(String method, String path) => '$method $path';
Map<String, dynamic> _paged(List<Map<String, dynamic>> results) => {
      'count': results.length,
      'next': null,
      'previous': null,
      'results': results
    };
Map<String, dynamic> _fareJson() => {
      'id': 'fare-1',
      'route': _routeRefJson(),
      'service_class': {
        'id': 'class-1',
        'code': 'ECONOMIE',
        'name': 'Économie',
        'allows_seat_selection': false,
        'is_active': true
      },
      'amount': '7000.00',
      'currency': 'XOF',
      'is_active': true,
      'created_at': '',
      'updated_at': ''
    };
Map<String, dynamic> _routeJson() => {
      'id': 'route-1',
      'company': _companyRef(),
      'departure_station': _stationRef(),
      'departure_city': _cityRef('city-1', 'Abidjan'),
      'destination_city': _cityRef('city-2', 'Bouake'),
      'destination_name': 'Bouake',
      'is_active': true,
      'created_at': '',
      'updated_at': ''
    };
Map<String, dynamic> _routeRefJson() => {
      'id': 'route-1',
      'departure_station': _stationRef(),
      'destination_city': _cityRef('city-2', 'Bouake'),
      'destination_name': 'Bouake',
      'is_active': true
    };
Map<String, dynamic> _companyRef() =>
    {'id': 'company-1', 'name': 'CA TRANS', 'code': 'CAT', 'is_active': true};
Map<String, dynamic> _stationRef() => {
      'id': 'station-1',
      'name': 'Gare Yopougon',
      'code': 'YOP',
      'city_name': 'Abidjan',
      'is_active': true
    };
Map<String, dynamic> _cityRef(String id, String name) =>
    {'id': id, 'name': name, 'country': "Côte d'Ivoire", 'is_active': true};
