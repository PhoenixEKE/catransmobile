import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fare_form_dialog.dart';

void main() {
  testWidgets('creates fare with typed payload', (tester) async {
    AdminFareFormResult? result;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showAdminFareFormDialog(
            context: context,
            isSubmitting: false,
            routes: const [_route],
            serviceClasses: const [_serviceClass],
          );
        },
        child: const Text('Open'),
      );
    }))));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester
        .tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Route *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gare Yopougon -> Bouake').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(
        DropdownButtonFormField<String?>, 'Classe de service *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Économie').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Montant *'), '7000,00');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(result?.createRequest?.toJson(), {
      'route_id': 'route-1',
      'service_class_id': 'class-1',
      'amount': '7000.00',
      'currency': 'XOF',
    });
  });

  testWidgets('rejects invalid amount', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AdminFareFormDialog(
                isSubmitting: false,
                routes: [_route],
                serviceClasses: [_serviceClass]))));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Montant *'), '0');
    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(
        find.text('Le montant doit être strictement positif.'), findsOneWidget);
  });
}

const _route = AdminRoute(
    id: 'route-1',
    company: AdminTransportCompanyRef(
        id: 'company-1', name: 'CA TRANS', code: 'CAT', isActive: true),
    departureStation: AdminTransportStationRef(
        id: 'station-1',
        name: 'Gare Yopougon',
        code: 'YOP',
        cityName: 'Abidjan',
        isActive: true),
    destinationName: 'Bouake',
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _serviceClass = AdminServiceClass(
    id: 'class-1',
    code: 'ECONOMIE',
    name: 'Économie',
    defaultLoyaltyPoints: 5,
    rewardThresholdPoints: 100,
    allowsSeatSelection: false,
    isActive: true,
    createdAt: '',
    updatedAt: '');
