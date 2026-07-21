import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_station_form_dialog.dart';

void main() {
  testWidgets('station form requires company and name', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Créer'));
    await tester.pump();
    expect(find.text('Compagnie est obligatoire.'), findsOneWidget);
    expect(find.text('Nom est obligatoire.'), findsOneWidget);
  });

  testWidgets('station form shows field error and supports nullable city', (tester) async {
    await pumpForm(tester, error: const StructuredApiError(code: 'transport_company_inactive', detail: 'La compagnie sélectionnée est inactive.', field: 'company_id'));
    expect(find.text('La compagnie sélectionnée est inactive.'), findsOneWidget);
    expect(find.text('Aucune ville'), findsOneWidget);
  });
}

Future<void> pumpForm(WidgetTester tester, {StructuredApiError? error}) async { await tester.binding.setSurfaceSize(const Size(680, 680)); addTearDown(() async => tester.binding.setSurfaceSize(null)); await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdminStationFormDialog(isSubmitting: false, companies: const [_company], cities: const [_city], error: error)))); }
const _company = AdminCompany(id: 'company-1', name: 'CA TRANS', code: 'CAT', customerServicePhone: null, isActive: true, createdAt: '', updatedAt: '');
const _city = AdminCity(id: 'city-1', name: 'Abidjan', normalizedName: 'abidjan', country: "Côte d'Ivoire", isActive: true, createdAt: '', updatedAt: '');
