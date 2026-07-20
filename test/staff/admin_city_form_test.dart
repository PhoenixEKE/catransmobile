import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_city_form_dialog.dart';

void main() {
  testWidgets('city form validates required fields', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(find.text('Nom est obligatoire.'), findsOneWidget);
  });

  testWidgets('city form shows field error and draft', (tester) async {
    await pumpForm(
      tester,
      error: const StructuredApiError(
        code: 'transport_duplicate_city',
        detail: 'Une ville existe déjà avec ce nom dans ce pays.',
        field: 'name',
      ),
      createDraft: const AdminCityCreateRequest(
        name: 'San Pedro',
        country: "Côte d'Ivoire",
      ),
    );

    expect(find.widgetWithText(TextFormField, 'San Pedro'), findsOneWidget);
    expect(find.text('Une ville existe déjà avec ce nom dans ce pays.'), findsOneWidget);
  });
}

Future<void> pumpForm(
  WidgetTester tester, {
  StructuredApiError? error,
  AdminCityCreateRequest? createDraft,
}) async {
  await tester.binding.setSurfaceSize(const Size(560, 520));
  addTearDown(() async => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AdminCityFormDialog(
        isSubmitting: false,
        error: error,
        initialCreateRequest: createDraft,
      ),
    ),
  ));
}
