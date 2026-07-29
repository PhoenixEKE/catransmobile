import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_class_form_dialog.dart';

void main() {
  testWidgets('service class form validates required fields', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(find.text('Code est obligatoire.'), findsOneWidget);
    expect(find.text('Nom est obligatoire.'), findsOneWidget);
  });

  testWidgets('service class form shows code error and draft values', (tester) async {
    await pumpForm(
      tester,
      error: const StructuredApiError(
        code: 'transport_duplicate_service_class_code',
        detail: 'Une classe de service utilise déjà ce code.',
        field: 'code',
      ),
      createDraft: const AdminServiceClassCreateRequest(
        code: 'ECONOMIE',
        name: 'Économie',
        defaultLoyaltyPoints: 5,
        rewardThresholdPoints: 50,
        allowsSeatSelection: false,
      ),
    );

    expect(find.widgetWithText(TextFormField, 'ECONOMIE'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '5'), findsOneWidget);
    expect(find.text('Une classe de service utilise déjà ce code.'), findsOneWidget);
  });
}

Future<void> pumpForm(
  WidgetTester tester, {
  StructuredApiError? error,
  AdminServiceClassCreateRequest? createDraft,
}) async {
  await tester.binding.setSurfaceSize(const Size(620, 620));
  addTearDown(() async => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AdminServiceClassFormDialog(
        isSubmitting: false,
        error: error,
        initialCreateRequest: createDraft,
      ),
    ),
  ));
}
