import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_transition_dialog.dart';

void main() {
  test('departure transitions follow backend states only', () {
    final scheduled = AdminDeparture.fromJson({
      'id': 'd1',
      'departure_date': '2026-07-21',
      'status': {'code': 'scheduled', 'label': 'Prévu'},
    });
    final open = AdminDeparture.fromJson({
      'id': 'd2',
      'departure_date': '2026-07-21',
      'status': {'code': 'open', 'label': 'Ouvert'},
    });
    final closed = AdminDeparture.fromJson({
      'id': 'd3',
      'departure_date': '2026-07-21',
      'status': {'code': 'closed', 'label': 'Fermé'},
    });

    expect(scheduled.canOpen, isTrue);
    expect(scheduled.canClose, isFalse);
    expect(open.canClose, isTrue);
    expect(open.canOpen, isFalse);
    expect(closed.canDepart, isTrue);
  });

  testWidgets('transition confirmation dialog returns true on confirm',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final departure = AdminDeparture.fromJson({
      'id': 'departure-1',
      'departure_date': '2026-07-21',
      'status': {'code': 'scheduled', 'label': 'Prévu'},
    });

    final future = showAdminDepartureTransitionDialog(
      context: tester.element(find.byType(Scaffold)),
      departure: departure,
      action: 'open',
      isSubmitting: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-departure-open-confirm')));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });
}
