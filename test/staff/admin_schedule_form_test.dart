import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedule_form_dialog.dart';

void main() {
  test('create request keeps backend schedule payload', () {
    const request = AdminScheduleCreateRequest(
      stationId: 'station-1',
      routeId: 'route-1',
      serviceClassId: 'class-1',
      departureTime: '08:00:00',
      routeNote: 'Direct',
    );

    expect(request.toJson(), {
      'station_id': 'station-1',
      'route_id': 'route-1',
      'service_class_id': 'class-1',
      'departure_time': '08:00',
      'route_note': 'Direct',
    });
  });

  testWidgets('validates missing required schedule fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AdminScheduleFormDialog(
                isSubmitting: false,
                stations: [_station],
                routes: [_route],
                serviceClasses: [_serviceClass]))));

    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(find.text('Ce champ est obligatoire.'), findsNWidgets(3));
    expect(find.text('L’heure de départ est obligatoire.'), findsOneWidget);
  });

  testWidgets('validates schedule time format', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AdminScheduleFormDialog(
                isSubmitting: false,
                stations: [_station],
                routes: [_route],
                serviceClasses: [_serviceClass]))));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Heure de départ *'), '25:00');
    await tester.tap(find.text('Créer'));
    await tester.pump();

    expect(find.text('Utilisez le format HH:mm.'), findsOneWidget);
  });
}

const _companyRef = AdminTransportCompanyRef(
    id: 'company-1', name: 'CA TRANS', code: 'CAT', isActive: true);
const _cityRef = AdminTransportCityRef(
    id: 'city-1', name: 'Abidjan', country: 'CI', isActive: true);
const _destinationRef = AdminTransportCityRef(
    id: 'city-2', name: 'Bouake', country: 'CI', isActive: true);
const _stationRef = AdminTransportStationRef(
    id: 'station-1', name: 'Gare Yopougon', cityName: 'Abidjan', isActive: true);
const _station = AdminStation(
    id: 'station-1',
    name: 'Gare Yopougon',
    normalizedName: 'gare yopougon',
    cityNameSnapshot: 'Abidjan',
    cityName: 'Abidjan',
    company: _companyRef,
    city: _cityRef,
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _route = AdminRoute(
    id: 'route-1',
    company: _companyRef,
    departureStation: _stationRef,
    departureCity: _cityRef,
    destinationCity: _destinationRef,
    destinationName: 'Bouake',
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _serviceClass = AdminServiceClass(
    id: 'class-1',
    code: 'ECONOMIE',
    name: 'Économie',
    defaultLoyaltyPoints: 0,
    rewardThresholdPoints: 0,
    allowsSeatSelection: false,
    isActive: true,
    createdAt: '',
    updatedAt: '');
