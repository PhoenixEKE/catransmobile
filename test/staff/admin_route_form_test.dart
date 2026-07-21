import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_route_form_dialog.dart';

void main() {
  testWidgets('creates route with free destination and no is_active field',
      (tester) async {
    AdminRouteFormResult? result;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showAdminRouteFormDialog(
            context: context,
            isSubmitting: false,
            companies: const [_company],
            stations: const [_station],
            cities: const [_city],
          );
        },
        child: const Text('Open'),
      );
    }))));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String?>, 'Compagnie *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CA TRANS').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(
        DropdownButtonFormField<String?>, 'Gare de départ *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gare Yopougon').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Destination libre'), 'Korhogo');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    final request = result?.createRequest;
    expect(request, isNotNull);
    expect(request!.toJson(), {
      'company_id': 'company-1',
      'departure_station_id': 'station-1',
      'destination_name': 'Korhogo',
    });
    expect(request.toJson().containsKey('is_active'), isFalse);
  });

  testWidgets('validates missing destination', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AdminRouteFormDialog(
                isSubmitting: false,
                companies: [_company],
                stations: [_station],
                cities: [_city]))));

    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(find.text('Compagnie est obligatoire.'), findsOneWidget);
    expect(find.text('Gare de départ est obligatoire.'), findsOneWidget);
    expect(find.text('Une destination est obligatoire.'), findsOneWidget);
  });
}

const _company = AdminCompany(
    id: 'company-1',
    name: 'CA TRANS',
    code: 'CAT',
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _city = AdminCity(
    id: 'city-2',
    name: 'Bouake',
    normalizedName: 'bouake',
    country: "Côte d'Ivoire",
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _station = AdminStation(
    id: 'station-1',
    name: 'Gare Yopougon',
    normalizedName: 'gare yopougon',
    code: 'YOP',
    cityNameSnapshot: 'Abidjan',
    cityName: 'Abidjan',
    company: AdminTransportCompanyRef(
        id: 'company-1', name: 'CA TRANS', code: 'CAT', isActive: true),
    isActive: true,
    createdAt: '',
    updatedAt: '');
