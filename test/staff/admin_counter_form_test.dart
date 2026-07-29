import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counter_form_dialog.dart';

void main() {
  testWidgets('counter form requires code and label', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Créer'));
    await tester.pump();
    expect(find.text('Code est obligatoire.'), findsOneWidget);
    expect(find.text('Libellé est obligatoire.'), findsOneWidget);
  });

  testWidgets('counter form shows station context and field error', (tester) async {
    await pumpForm(tester, error: const StructuredApiError(code: 'transport_counter_duplicate_code', detail: 'Un guichet de cette gare utilise déjà ce code.', field: 'code'));
    expect(find.text('Gare : Gare Yopougon'), findsOneWidget);
    expect(find.text('Un guichet de cette gare utilise déjà ce code.'), findsOneWidget);
  });
}

Future<void> pumpForm(WidgetTester tester, {StructuredApiError? error}) async { await tester.binding.setSurfaceSize(const Size(520, 520)); addTearDown(() async => tester.binding.setSurfaceSize(null)); await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdminCounterFormDialog(isSubmitting: false, stationName: 'Gare Yopougon', error: error)))); }
