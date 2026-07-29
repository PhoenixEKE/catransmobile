import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin transport base references regression', () {
    test('counter create payload does not contain station_id', () {
      const request = AdminStationCounterCreateRequest(code: 'G01', label: 'Guichet 01');
      expect(request.toJson().containsKey('station_id'), isFalse);
    });

    test('counter API keeps station scoped list and create endpoints', () async {
      final fake = _RecordingTransport();
      final service = AdminTransportBaseApiService(transport: fake);
      await service.listCounters(stationId: 'station-1');
      await service.createCounter(stationId: 'station-1', request: const AdminStationCounterCreateRequest(code: 'G01', label: 'Guichet 01'));
      expect(fake.paths, contains('GET admin/transport/stations/station-1/counters/'));
      expect(fake.paths, contains('POST admin/transport/stations/station-1/counters/'));
      expect(fake.paths.any((path) => path.contains('admin/users/counters')), isFalse);
    });
  });
}

class _RecordingTransport implements AdminTransportBaseApiTransport {
  final paths = <String>[];
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async { paths.add('GET $path'); return {'count': 0, 'next': null, 'previous': null, 'results': []}; }
  @override
  Future<dynamic> post(String path, {dynamic data}) async { paths.add('POST $path'); return {'id': 'counter-1', 'station': {'id': 'station-1', 'name': 'Gare', 'code': 'GAR', 'city_name': 'Abidjan', 'is_active': true}, 'code': 'G01', 'label': 'Guichet 01', 'is_active': true, 'created_at': '', 'updated_at': ''}; }
  @override
  Future<dynamic> patch(String path, {dynamic data}) async { paths.add('PATCH $path'); return {}; }
}
