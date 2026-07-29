import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('AdminTransportBaseApiService queries', () {
    test('omits empty values and does not impose pagination by default', () {
      final query = buildAdminTransportBaseQueryParameters(
        query: ' Yop ',
        isActive: false,
        ordering: ' name ',
        extra: {'country': ' ', 'company_id': 'company-1'},
      );

      expect(query, {
        'q': 'Yop',
        'is_active': false,
        'ordering': 'name',
        'company_id': 'company-1',
      });
      expect(query.containsKey('page'), isFalse);
      expect(query.containsKey('page_size'), isFalse);
    });

    test('bounds explicit pagination to backend limits', () {
      final query = buildAdminTransportBaseQueryParameters(
        page: 0,
        pageSize: 250,
      );

      expect(query['page'], 1);
      expect(query['page_size'], 100);
    });
  });

  group('AdminTransportBaseApiService endpoints', () {
    test('lists and parses companies with paged response', () async {
      final fake = _FakeTransport({
        _key('GET', 'admin/transport/companies/'): _paged([
          _companyJson(id: 'company-1'),
        ]),
      });
      final service = AdminTransportBaseApiService(transport: fake);

      final page = await service.listCompanies(query: 'ca', page: 2);

      expect(page.count, 1);
      expect(page.results.single.id, 'company-1');
      expect(fake.requests.single.path, 'admin/transport/companies/');
      expect(fake.requests.single.queryParameters, {'page': 2, 'q': 'ca'});
    });

    test('uses typed city filters', () async {
      final fake = _FakeTransport({
        _key('GET', 'admin/transport/cities/'): _paged([_cityJson()]),
      });
      final service = AdminTransportBaseApiService(transport: fake);

      await service.listCities(country: 'CI', isActive: true);

      expect(fake.requests.single.queryParameters, {
        'is_active': true,
        'country': 'CI',
      });
    });

    test('uses typed station filters', () async {
      final fake = _FakeTransport({
        _key('GET', 'admin/transport/stations/'): _paged([_stationJson()]),
      });
      final service = AdminTransportBaseApiService(transport: fake);

      await service.listStations(companyId: 'company-1', cityId: 'city-1');

      expect(fake.requests.single.queryParameters, {
        'company_id': 'company-1',
        'city_id': 'city-1',
      });
    });

    test('uses station-scoped counter endpoints and never admin/users/counters', () async {
      final fake = _FakeTransport({
        _key('GET', 'admin/transport/stations/station-1/counters/'):
            _paged([_counterJson()]),
        _key('POST', 'admin/transport/stations/station-1/counters/'):
            _counterJson(),
      });
      final service = AdminTransportBaseApiService(transport: fake);

      await service.listCounters(stationId: 'station-1');
      await service.createCounter(
        stationId: 'station-1',
        request: const AdminStationCounterCreateRequest(
          code: 'A1',
          label: 'Guichet A1',
        ),
      );

      expect(fake.requests[0].path, 'admin/transport/stations/station-1/counters/');
      expect(fake.requests[1].path, 'admin/transport/stations/station-1/counters/');
      expect(fake.requests[1].body, {'code': 'A1', 'label': 'Guichet A1'});
      expect(fake.requests[1].body.containsKey('station_id'), isFalse);
      expect(
        fake.requests.any((request) => request.path.contains('admin/users/counters')),
        isFalse,
      );
      expect(
        fake.requests.any(
          (request) =>
              request.method != 'GET' &&
              request.path == 'admin/transport/counters/',
        ),
        isFalse,
      );
    });

    test('uses service class allows_seat_selection filter', () async {
      final fake = _FakeTransport({
        _key('GET', 'admin/transport/service-classes/'): _paged([
          _serviceClassJson(),
        ]),
      });
      final service = AdminTransportBaseApiService(transport: fake);

      await service.listServiceClasses(allowsSeatSelection: true);

      expect(fake.requests.single.queryParameters, {
        'allows_seat_selection': true,
      });
    });

    test('uses typed create, update and action endpoints', () async {
      final fake = _FakeTransport({
        _key('POST', 'admin/transport/companies/'): _companyJson(),
        _key('PATCH', 'admin/transport/companies/company-1/'): _companyJson(),
        _key('POST', 'admin/transport/companies/company-1/activate/'): {
          'activated': true,
          'object': _companyJson(),
        },
      });
      final service = AdminTransportBaseApiService(transport: fake);

      await service.createCompany(
        const AdminCompanyCreateRequest(name: 'CA TRANS'),
      );
      await service.updateCompany(
        'company-1',
        const AdminCompanyUpdateRequest(
          code: AdminTransportPatchField.clear(),
        ),
      );
      await service.activateCompany('company-1');

      expect(fake.requests[0].body, {'name': 'CA TRANS'});
      expect(fake.requests[1].body, {'code': null});
      expect(fake.requests[2].path, 'admin/transport/companies/company-1/activate/');
    });
  });

  group('AdminTransportBaseApiService errors', () {
    test('keeps structured backend error details available', () {
      final error = StructuredApiError.fromException(
        ApiException(
          message: 'Une compagnie utilise déjà ce code.',
          statusCode: 400,
          details: const {
            'code': 'transport_duplicate_company_code',
            'detail': 'Une compagnie utilise déjà ce code.',
            'field': 'code',
          },
        ),
      );

      expect(error.code, 'transport_duplicate_company_code');
      expect(error.field, 'code');
      expect(error.detail, 'Une compagnie utilise déjà ce code.');
    });

    test('fake transport fails fast when an unexpected network call is attempted', () {
      final fake = _FakeTransport(const {});
      final service = AdminTransportBaseApiService(transport: fake);

      expect(service.listCompanies(), throwsA(isA<StateError>()));
    });
  });
}

class _FakeTransport implements AdminTransportBaseApiTransport {
  final Map<String, dynamic> responses;
  final List<_RecordedRequest> requests = [];

  _FakeTransport(this.responses);

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    requests.add(
      _RecordedRequest(
        method: 'GET',
        path: path,
        queryParameters: queryParameters ?? const {},
      ),
    );
    return _responseFor('GET', path);
  }

  @override
  Future<dynamic> post(String path, {dynamic data}) async {
    requests.add(
      _RecordedRequest(
        method: 'POST',
        path: path,
        body: data as Map<String, dynamic>? ?? const {},
      ),
    );
    return _responseFor('POST', path);
  }

  @override
  Future<dynamic> patch(String path, {dynamic data}) async {
    requests.add(
      _RecordedRequest(
        method: 'PATCH',
        path: path,
        body: data as Map<String, dynamic>? ?? const {},
      ),
    );
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

class _RecordedRequest {
  final String method;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> body;

  const _RecordedRequest({
    required this.method,
    required this.path,
    this.queryParameters = const {},
    this.body = const {},
  });
}

String _key(String method, String path) => '$method $path';

Map<String, dynamic> _paged(List<Map<String, dynamic>> results) => {
      'count': results.length,
      'next': null,
      'previous': null,
      'results': results,
    };

Map<String, dynamic> _companyJson({String id = 'company-1'}) => {
      'id': id,
      'name': 'CA TRANS',
      'code': 'CAT',
      'customer_service_phone': null,
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _cityJson() => {
      'id': 'city-1',
      'name': 'Yopougon',
      'normalized_name': 'yopougon',
      'country': "Côte d'Ivoire",
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _stationJson() => {
      'id': 'station-1',
      'name': 'Gare Yopougon',
      'normalized_name': 'gare-yopougon',
      'code': 'YOP',
      'phone_line': null,
      'representative': null,
      'city_name_snapshot': 'Abidjan',
      'city_name': 'Yopougon',
      'company': {
        'id': 'company-1',
        'name': 'CA TRANS',
        'code': 'CAT',
        'is_active': true,
      },
      'city': {
        'id': 'city-1',
        'name': 'Yopougon',
        'country': "Côte d'Ivoire",
        'is_active': true,
      },
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _counterJson() => {
      'id': 'counter-1',
      'station': {
        'id': 'station-1',
        'name': 'Gare Yopougon',
        'code': 'YOP',
        'city_name': 'Yopougon',
        'is_active': true,
      },
      'code': 'A1',
      'label': 'Guichet A1',
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _serviceClassJson() => {
      'id': 'class-1',
      'code': 'PRESTIGE',
      'name': 'Prestige',
      'default_loyalty_points': 10,
      'reward_threshold_points': 100,
      'allows_seat_selection': true,
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };
