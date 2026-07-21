import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';

void main() {
  test('parses route destination city and free destination safely', () {
    final route = AdminRoute.fromJson(
        _routeJson(destinationCity: _cityRef('city-2', 'Bouake')));
    expect(route.displayDestination, 'Bouake');

    final freeDestination = AdminRoute.fromJson(
        _routeJson(destinationCity: null, destinationName: 'Korhogo'));
    expect(freeDestination.displayDestination, 'Korhogo');
  });

  test('route create request sends ids and never unknown fields', () {
    const request = AdminRouteCreateRequest(
      companyId: 'company-1',
      departureStationId: 'station-1',
      destinationName: 'Korhogo',
    );

    expect(request.toJson(), {
      'company_id': 'company-1',
      'departure_station_id': 'station-1',
      'destination_name': 'Korhogo',
    });
    expect(request.toJson().containsKey('is_active'), isFalse);
  });

  test('fare create and replace keep amount as string and XOF currency', () {
    const create = AdminFareCreateRequest(
      routeId: 'route-1',
      serviceClassId: 'class-1',
      amount: '7000.00',
    );
    const replace = AdminFareReplaceRequest(amount: '8000.00');

    expect(create.toJson(), {
      'route_id': 'route-1',
      'service_class_id': 'class-1',
      'amount': '7000.00',
      'currency': 'XOF',
    });
    expect(replace.toJson(), {'amount': '8000.00', 'currency': 'XOF'});
  });

  test('parses fare with route and service class refs', () {
    final fare = AdminFare.fromJson(_fareJson());

    expect(fare.route.displayLabel, 'Gare Yopougon -> Bouake');
    expect(fare.serviceClass.name, 'Économie');
    expect(fare.displayAmount, '7000.00 XOF');
  });

  test('parses schedule and normalizes time payload', () {
    final schedule = AdminSchedule.fromJson(_scheduleJson());

    expect(schedule.station.name, 'Gare Yopougon');
    expect(schedule.displayRoute, 'Gare Yopougon -> Bouake');
    expect(schedule.displayServiceClass, 'Économie');
    expect(schedule.displayTime, '08:00');
    expect(normalizeScheduleTime('08:00:00'), '08:00');
  });

  test('schedule create and update payloads keep backend field names', () {
    const create = AdminScheduleCreateRequest(
      stationId: 'station-1',
      routeId: 'route-1',
      serviceClassId: 'class-1',
      departureTime: '08:00:00',
      routeNote: 'Direct',
    );
    const update = AdminScheduleUpdateRequest(departureTime: '09:00');

    expect(create.toJson(), {
      'station_id': 'station-1',
      'route_id': 'route-1',
      'service_class_id': 'class-1',
      'departure_time': '08:00',
      'route_note': 'Direct',
    });
    expect(create.toJson().containsKey('is_active'), isFalse);
    expect(update.toJson(), {'departure_time': '09:00'});
  });
}

Map<String, dynamic> _fareJson() => {
      'id': 'fare-1',
      'route': _routeRefJson(),
      'service_class': {
        'id': 'class-1',
        'code': 'ECONOMIE',
        'name': 'Économie',
        'allows_seat_selection': false,
        'is_active': true,
      },
      'amount': '7000.00',
      'currency': 'XOF',
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _routeJson(
        {Map<String, dynamic>? destinationCity, String destinationName = ''}) =>
    {
      'id': 'route-1',
      'company': _companyRef(),
      'departure_station': _stationRef(),
      'departure_city': _cityRef('city-1', 'Abidjan'),
      'destination_city': destinationCity,
      'destination_name': destinationName,
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };

Map<String, dynamic> _routeRefJson() => {
      'id': 'route-1',
      'departure_station': _stationRef(),
      'destination_city': _cityRef('city-2', 'Bouake'),
      'destination_name': 'Bouake',
      'is_active': true,
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

Map<String, dynamic> _scheduleJson() => {
      'id': 'schedule-1',
      'station': _stationRef(),
      'route': _routeRefJson(),
      'service_class': {
        'id': 'class-1',
        'code': 'ECONOMIE',
        'name': 'Économie',
        'allows_seat_selection': false,
        'is_active': true,
      },
      'departure_time': '08:00:00',
      'departure_time_raw': '08:00',
      'route_note': 'Direct',
      'is_active': true,
      'created_at': '2026-07-20T08:00:00Z',
      'updated_at': '2026-07-20T09:00:00Z',
    };
