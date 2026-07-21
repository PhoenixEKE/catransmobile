import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/seats/admin_departure_seat_action_dialog.dart';

void main() {
  final seat = AdminDepartureSeat.fromJson({
    'id': 'seat-1',
    'seat_number': 1,
    'status': 'available',
    'seat_type': 'standard',
    'display_label': '1',
    'visual': {'row_number': 1, 'column_number': 1},
    'blocked': {'blocked_reason': ''},
    'active_hold_present': false,
  });

  testWidgets('seat action dialog requires reason', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    showAdminDepartureSeatActionDialog(
      context: tester.element(find.byType(Scaffold)),
      seat: seat,
      action: 'block',
      isSubmitting: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-seat-block-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Le motif est obligatoire.'), findsOneWidget);
  });

  testWidgets('seat action dialog returns reason on confirm', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final future = showAdminDepartureSeatActionDialog(
      context: tester.element(find.byType(Scaffold)),
      seat: seat,
      action: 'unblock',
      isSubmitting: false,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-seat-action-reason-field')),
      'Disponible',
    );
    await tester.tap(find.byKey(const Key('admin-seat-unblock-confirm')));
    await tester.pumpAndSettle();

    expect(await future, 'Disponible');
  });
}
