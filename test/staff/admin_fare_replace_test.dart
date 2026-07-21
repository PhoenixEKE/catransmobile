import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fare_replace_dialog.dart';

void main() {
  testWidgets('returns replace request and keeps fare context visible',
      (tester) async {
    AdminFareReplaceRequest? result;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showAdminFareReplaceDialog(
            context: context,
            isSubmitting: false,
            fare: _fare,
          );
        },
        child: const Text('Open'),
      );
    }))));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-fare-replace-dialog')), findsOneWidget);
    expect(find.text('Route : Gare Yopougon -> Bouake'), findsOneWidget);
    expect(find.text('Montant actuel : 7000.00 XOF'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau montant *'), '8000');
    await tester.tap(find.byKey(const Key('admin-fare-replace-confirm')));
    await tester.pumpAndSettle();

    expect(result?.toJson(), {'amount': '8000', 'currency': 'XOF'});
  });
}

const _fare = AdminFare(
  id: 'fare-1',
  route: AdminTransportRouteRef(
      id: 'route-1',
      departureStation: AdminTransportStationRef(
          id: 'station-1',
          name: 'Gare Yopougon',
          code: 'YOP',
          cityName: 'Abidjan',
          isActive: true),
      destinationName: 'Bouake',
      isActive: true),
  serviceClass: AdminTransportServiceClassRef(
      id: 'class-1',
      code: 'ECONOMIE',
      name: 'Économie',
      allowsSeatSelection: false,
      isActive: true),
  amount: '7000.00',
  currency: 'XOF',
  isActive: true,
  createdAt: '',
  updatedAt: '',
);
