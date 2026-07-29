import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seats_screen.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

void main() {
  testWidgets('requires a selected departure', (tester) async {
    await _pumpSeats(tester, departure: null, apiService: _FakeSeatService());
    await tester.pumpAndSettle();

    expect(find.text('Sélectionnez un départ'), findsOneWidget);
  });

  testWidgets('renders counters and hides actions in read only mode',
      (tester) async {
    await _pumpSeats(
      tester,
      departure: _departure,
      canManage: false,
      apiService: _FakeSeatService(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total : 2'), findsOneWidget);
    expect(find.text('Disponibles : 1'), findsOneWidget);
    expect(find.byKey(const Key('admin-seat-block-seat-1')), findsNothing);
  });
}

Future<void> _pumpSeats(
  WidgetTester tester, {
  required AdminDeparture? departure,
  required AdminOperationsApiService apiService,
  bool canManage = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 760));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 680,
        child: AdminDepartureSeatsScreen(
          departure: departure,
          canManage: canManage,
          apiService: apiService,
        ),
      ),
    ),
  ));
}

class _FakeSeatService extends AdminOperationsApiService {
  @override
  Future<AdminDepartureSeatsResponse> listDepartureSeats({
    required String departureId,
    String? status,
    String? seatType,
    int? seatNumber,
    bool? isSelectable,
    String? ordering,
  }) async {
    return AdminDepartureSeatsResponse.fromJson({
      'departure_id': departureId,
      'count': 2,
      'results': [_seat(1, 'available'), _seat(2, 'blocked')],
    });
  }

  @override
  Future<AdminDepartureSeatMap> getAdminDepartureSeatMap(
      String departureId) async {
    return AdminDepartureSeatMap.fromJson({
      'departure': {'id': departureId},
      'layout': {'id': 'layout-1'},
      'seats_generated': true,
      'counts': {
        'total': 2,
        'available': 1,
        'held': 0,
        'reserved': 0,
        'blocked': 1,
      },
      'zones': [],
      'seats': [],
    });
  }
}

final _departure = AdminDeparture.fromJson({
  'id': 'departure-1',
  'station': {'id': 'station-1', 'name': 'Gare Yopougon'},
  'route': {'id': 'route-1', 'label': 'Gare Yopougon -> Bouake'},
  'service_class': {'id': 'class-1', 'code': 'PRESTIGE', 'name': 'Prestige'},
  'departure_date': '2026-07-21',
  'departure_time': '08:00',
  'status': {'code': 'scheduled', 'label': 'Prévu'},
});

Map<String, dynamic> _seat(int number, String status) => {
      'id': 'seat-$number',
      'seat_number': number,
      'status': status,
      'seat_type': 'standard',
      'display_label': '$number',
      'visual': {'row_number': 1, 'column_number': number},
      'blocked': {'blocked_reason': ''},
      'active_hold_present': false,
    };
