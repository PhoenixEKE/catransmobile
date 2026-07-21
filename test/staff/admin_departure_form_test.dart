import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_form_dialog.dart';

void main() {
  testWidgets('create form requires template and date', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    showAdminDepartureFormDialog(
      context: tester.element(find.byType(Scaffold)),
      isSubmitting: false,
      templates: const [
        AdminOperationRecord(
          id: 'template-1',
          name: 'Template 08:00',
          isActive: true,
        )
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-departure-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Le template est obligatoire.'), findsOneWidget);
    expect(find.text('La date est obligatoire.'), findsOneWidget);
  });

  testWidgets('edit form returns date update request', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final future = showAdminDepartureFormDialog(
      context: tester.element(find.byType(Scaffold)),
      isSubmitting: false,
      templates: const [],
      initialDeparture: AdminDeparture.fromJson({
        'id': 'departure-1',
        'departure_date': '2026-07-21',
        'status': {'code': 'scheduled', 'label': 'Prévu'},
      }),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-departure-date-field')),
      '2026-07-22',
    );
    await tester.tap(find.byKey(const Key('admin-departure-form-submit')));
    await tester.pumpAndSettle();

    final result = await future;
    expect(result?.updateRequest?.departureDate, '2026-07-22');
  });
}
