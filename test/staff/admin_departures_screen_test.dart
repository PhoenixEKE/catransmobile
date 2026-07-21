import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_screen.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

void main() {
  testWidgets('loading then empty state is deterministic', (tester) async {
    final started = Completer<void>();
    final result = Completer<PagedResult<AdminDeparture>>();
    await _pumpDepartures(
      tester,
      apiService: _FakeOperationsService(
        departuresStarted: started,
        departuresCompleter: result,
      ),
    );
    await tester.pump();
    await started.future;
    await tester.pump();

    expect(find.text('Chargement des départs...'), findsOneWidget);

    result.complete(const PagedResult(
      count: 0,
      next: null,
      previous: null,
      results: [],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Aucun départ'), findsOneWidget);
  });

  testWidgets('read only hides departure mutation actions', (tester) async {
    await _pumpDepartures(
      tester,
      canManage: false,
      apiService: _FakeOperationsService(),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026-07-21 à 08:00'), findsOneWidget);
    expect(find.byKey(const Key('admin-departures-create')), findsNothing);
    expect(find.byKey(const Key('admin-departure-open-departure-1')),
        findsNothing);
  });

  testWidgets('selecting seats keeps selected departure visible',
      (tester) async {
    AdminDeparture? selected;
    String section = 'departures';
    await _pumpDepartures(
      tester,
      apiService: _FakeOperationsService(),
      onDepartureSelected: (departure) => selected = departure,
      onOpenSeats: (departure) => section = 'seats',
    );
    await tester.pumpAndSettle();

    final finder = find.byKey(const Key('admin-departure-seats-departure-1'));
    expect(finder, findsOneWidget);
    tester.widget<IconButton>(finder).onPressed!.call();
    await tester.pump();

    expect(selected?.id, 'departure-1');
    expect(section, 'seats');
  });
}

Future<void> _pumpDepartures(
  WidgetTester tester, {
  required AdminOperationsApiService apiService,
  bool canManage = true,
  ValueChanged<AdminDeparture>? onDepartureSelected,
  ValueChanged<AdminDeparture>? onOpenSeats,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 720,
        child: AdminDeparturesScreen(
          canManage: canManage,
          selectedDeparture: null,
          apiService: apiService,
          onDepartureSelected: onDepartureSelected ?? (_) {},
          onOpenSeats: onOpenSeats ?? (_) {},
          onOpenBoarding: (_) {},
        ),
      ),
    ),
  ));
}

class _FakeOperationsService extends AdminOperationsApiService {
  final Completer<void>? departuresStarted;
  final Completer<PagedResult<AdminDeparture>>? departuresCompleter;

  _FakeOperationsService({this.departuresStarted, this.departuresCompleter});

  @override
  Future<PagedResult<AdminOperationRecord>> listDepartureTemplates({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [
        AdminOperationRecord(
          id: 'template-1',
          name: 'Gare Yopougon 08:00',
          isActive: true,
        ),
      ],
    );
  }

  @override
  Future<PagedResult<AdminDeparture>> listAdminDepartures({
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTemplateId,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (departuresStarted != null && !departuresStarted!.isCompleted) {
      departuresStarted!.complete();
    }
    if (departuresCompleter != null) return departuresCompleter!.future;
    return PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_departure],
    );
  }
}

final _departure = AdminDeparture.fromJson({
  'id': 'departure-1',
  'departure_template_id': 'template-1',
  'station': {'id': 'station-1', 'name': 'Gare Yopougon'},
  'route': {'id': 'route-1', 'label': 'Gare Yopougon -> Bouake'},
  'service_class': {'id': 'class-1', 'code': 'PRESTIGE', 'name': 'Prestige'},
  'seat_layout': {'id': 'layout-1', 'name': 'Bus 40'},
  'departure_date': '2026-07-21',
  'departure_time': '08:00',
  'status': {'code': 'scheduled', 'label': 'Prévu'},
});
