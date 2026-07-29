import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_screen.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';

void main() {
  testWidgets('requires a selected departure', (tester) async {
    await _pumpBoarding(
      tester,
      departure: null,
      adminApiService: _FakeBoardingAdminService(),
      stationApiService: _FakeStationBoardingService(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sélectionnez un départ'), findsOneWidget);
  });

  testWidgets('scope banners disable validation controls', (tester) async {
    await _pumpBoarding(
      tester,
      departure: _departure,
      canValidate: false,
      canReadManifest: false,
      adminApiService: _FakeBoardingAdminService(),
      stationApiService: _FakeStationBoardingService(),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('boarding.validate'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('admin-boarding-validate-reference')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('manual reference validation shows backend result',
      (tester) async {
    final adminApiService = _FakeBoardingAdminService();
    await _pumpBoarding(
      tester,
      departure: _departure,
      adminApiService: adminApiService,
      stationApiService: _FakeStationBoardingService(),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-boarding-reference-field')),
      'TCK-ABC123',
    );
    await tester
        .tap(find.byKey(const Key('admin-boarding-validate-reference')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-boarding-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Billet validé'), findsOneWidget);
    expect(find.text('Ticket : TCK-ABC123'), findsOneWidget);
    expect(adminApiService.lastTicketReference, 'TCK-ABC123');
  });
}

Future<void> _pumpBoarding(
  WidgetTester tester, {
  required AdminDeparture? departure,
  required AdminOperationsApiService adminApiService,
  required StationBoardingApiService stationApiService,
  bool canValidate = true,
  bool canReadManifest = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 760));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 680,
        child: AdminBoardingScreen(
          departure: departure,
          canValidate: canValidate,
          canReadManifest: canReadManifest,
          adminApiService: adminApiService,
          stationApiService: stationApiService,
        ),
      ),
    ),
  ));
}

class _FakeBoardingAdminService extends AdminOperationsApiService {
  String? lastTicketReference;

  @override
  Future<StationTicketValidation> validateTicketByReference({
    required String ticketReference,
    required String departureId,
    String deviceIdentifier = 'admin_operations_portal',
  }) async {
    lastTicketReference = ticketReference;
    return StationTicketValidation(
      id: 'validation-1',
      ticketReference: ticketReference.trim(),
      status: 'accepted',
      statusLabel: 'Accepté',
      channel: 'station_agent',
      channelLabel: 'Agent gare',
      departureId: departureId,
      resultMessage: 'Ticket accepté.',
      travelerLastname: 'Kouadio',
      travelerFirstname: 'Eric',
      seatNumber: 12,
    );
  }
}

class _FakeStationBoardingService extends StationBoardingApiService {}

final _departure = AdminDeparture.fromJson({
  'id': 'departure-1',
  'station': {'id': 'station-1', 'name': 'Gare Yopougon'},
  'route': {'id': 'route-1', 'label': 'Gare Yopougon -> Bouake'},
  'service_class': {'id': 'class-1', 'code': 'PRESTIGE', 'name': 'Prestige'},
  'departure_date': '2026-07-21',
  'departure_time': '08:00',
  'status': {'code': 'open', 'label': 'Ouvert'},
});
