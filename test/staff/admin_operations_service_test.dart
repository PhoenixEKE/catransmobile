import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

void main() {
  test('builds bounded operations query parameters and drops empty values', () {
    final params = buildAdminOperationsQueryParameters(
      ordering: 'departure_date',
      page: 0,
      pageSize: 250,
      extra: {
        'station_id': 'station-1',
        'route_id': '',
        'service_class_id': null,
        'status': 'open',
        'date_from': '2026-07-21',
      },
    );

    expect(params['page'], 1);
    expect(params['page_size'], 100);
    expect(params['ordering'], 'departure_date');
    expect(params['station_id'], 'station-1');
    expect(params['status'], 'open');
    expect(params['date_from'], '2026-07-21');
    expect(params.containsKey('route_id'), isFalse);
    expect(params.containsKey('service_class_id'), isFalse);
  });

  test(
      'supports seats filters without inventing pagination for nested endpoint',
      () {
    final params = buildAdminOperationsQueryParameters(
      ordering: 'seat_number',
      extra: {
        'status': 'available',
        'seat_type': 'standard',
        'seat_number': 12,
        'is_selectable': true,
      },
    );
    params.removeWhere((key, value) => key == 'page' || key == 'page_size');

    expect(params, {
      'ordering': 'seat_number',
      'status': 'available',
      'seat_type': 'standard',
      'seat_number': 12,
      'is_selectable': true,
    });
  });
}
