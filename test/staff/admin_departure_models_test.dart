import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';

void main() {
  test('parses departure status and display fields from backend contract', () {
    final departure = AdminDeparture.fromJson(_departureJson(status: 'open'));

    expect(departure.id, 'departure-1');
    expect(departure.departureTemplateId, 'template-1');
    expect(departure.displaySchedule, '2026-07-21 à 08:00');
    expect(departure.displayRoute, 'Gare Yopougon -> Bouake');
    expect(departure.displayStation, 'Gare Yopougon');
    expect(departure.displayClass, 'Prestige');
    expect(departure.canClose, isTrue);
    expect(departure.canOpen, isFalse);
  });

  test('departure create and date update payloads send only supported fields',
      () {
    const create = AdminDepartureCreateRequest(
      departureTemplateId: 'template-1',
      departureDate: '2026-07-22',
    );
    const update = AdminDepartureDateUpdateRequest(
      departureDate: '2026-07-23',
    );

    expect(create.toJson(), {
      'departure_template_id': 'template-1',
      'departure_date': '2026-07-22',
    });
    expect(create.toJson().containsKey('status'), isFalse);
    expect(update.toJson(), {'departure_date': '2026-07-23'});
  });

  test('parses departure seats response and action payload', () {
    final seats = AdminDepartureSeatsResponse.fromJson({
      'departure_id': 'departure-1',
      'count': 2,
      'results': [_seatJson(1, 'available'), _seatJson(2, 'blocked')],
    });
    const action = AdminDepartureSeatActionRequest(
      seatNumbers: [1, 2],
      reason: 'Maintenance',
    );

    expect(seats.available, 1);
    expect(seats.blocked, 1);
    expect(seats.results.first.canBlock, isTrue);
    expect(action.toJson(), {
      'seat_numbers': [1, 2],
      'reason': 'Maintenance',
    });
  });

  test('parses seat map counters without deriving availability', () {
    final map = AdminDepartureSeatMap.fromJson({
      'departure': {'id': 'departure-1'},
      'layout': {'id': 'layout-1'},
      'seats_generated': true,
      'counts': {
        'total': 4,
        'available': 1,
        'held': 1,
        'reserved': 1,
        'blocked': 1,
      },
      'zones': [],
      'seats': [],
    });

    expect(map.seatsGenerated, isTrue);
    expect(map.total, 4);
    expect(map.available, 1);
    expect(map.held, 1);
    expect(map.reserved, 1);
    expect(map.blocked, 1);
  });
}

Map<String, dynamic> _departureJson({String status = 'scheduled'}) => {
      'id': 'departure-1',
      'departure_template_id': 'template-1',
      'station': {'id': 'station-1', 'name': 'Gare Yopougon'},
      'route': {'id': 'route-1', 'label': 'Gare Yopougon -> Bouake'},
      'service_class': {
        'id': 'class-1',
        'code': 'PRESTIGE',
        'name': 'Prestige',
      },
      'seat_layout': {'id': 'layout-1', 'name': 'Bus 40'},
      'departure_date': '2026-07-21',
      'departure_time': '08:00',
      'status': {'code': status, 'label': status},
    };

Map<String, dynamic> _seatJson(int number, String status) => {
      'id': 'seat-$number',
      'seat_number': number,
      'status': status,
      'seat_type': 'standard',
      'display_label': '$number',
      'visual': {'row_number': 1, 'column_number': number},
      'blocked': {'blocked_reason': ''},
      'active_hold_present': false,
    };
