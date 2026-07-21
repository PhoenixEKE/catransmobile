import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/station_cash_models.dart';
import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';
import 'package:catrans_app/models/station/station_departure.dart';
import 'package:catrans_app/screens/staff/counter/counter_sales_screen.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';
import 'package:catrans_app/services/api/station_counter_api_service.dart';
import 'package:catrans_app/services/api/station_operational_departures_api_service.dart';

void main() {
  testWidgets('mobile 320x700 renders without losing controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 320,
            height: 700,
            child: CounterSalesScreen(
              user: _user,
              counterApiService: _FakeCounterApiService(),
              operationalApiService: _FakeOperationalApiService(),
              stationBoardingApiService: _FakeBoardingApiService(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('counter-sales-customer-id-field')),
        findsOneWidget);
    expect(find.byKey(const Key('counter-sales-create-reservation')),
        findsOneWidget);
  });

  testWidgets('prevents duplicate prestige seats before submit',
      (tester) async {
    final fakeApi = _FakeCounterApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterSalesScreen(
            user: _user,
            counterApiService: fakeApi,
            operationalApiService: _FakeOperationalApiService(),
            stationBoardingApiService: _FakeBoardingApiService(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-departure-id-field')),
      '22222222-2222-4222-8222-222222222222',
    );
    await _selectServiceClass(tester, 'PRESTIGE');

    await tester
        .ensureVisible(find.byKey(const Key('counter-sales-add-traveler')));
    await tester.tap(find.byKey(const Key('counter-sales-add-traveler')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-0-seat-number')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-seat-number')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-lastname')),
      'Kouadio',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-firstname')),
      'Eric',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-phone')),
      '0700000000',
    );

    await tester.ensureVisible(
        find.byKey(const Key('counter-sales-create-reservation')));
    await tester.tap(find.byKey(const Key('counter-sales-create-reservation')));
    await tester.pumpAndSettle();

    expect(
        find.text('Les sièges Prestige doivent être uniques.'), findsOneWidget);
    expect(fakeApi.createCalls, 0);
  });

  testWidgets('creates reservation then confirms cash', (tester) async {
    final fakeApi = _FakeCounterApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CounterSalesScreen(
            user: _user,
            counterApiService: fakeApi,
            operationalApiService: _FakeOperationalApiService(),
            stationBoardingApiService: _FakeBoardingApiService(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-departure-id-field')),
      '22222222-2222-4222-8222-222222222222',
    );
    await _selectServiceClass(tester, 'ECONOMIE');

    await tester
        .ensureVisible(find.byKey(const Key('counter-sales-add-traveler')));
    await tester.tap(find.byKey(const Key('counter-sales-add-traveler')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-lastname')),
      'Kouadio',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-firstname')),
      'Eric',
    );
    await tester.enterText(
      find.byKey(const Key('counter-sales-traveler-1-phone')),
      '0700000000',
    );

    await tester.ensureVisible(
        find.byKey(const Key('counter-sales-create-reservation')));
    await tester.tap(find.byKey(const Key('counter-sales-create-reservation')));
    await tester.pumpAndSettle();

    expect(fakeApi.createCalls, 1);
    expect(fakeApi.lastCreateRequest?.serviceClassCode, 'ECONOMIE');
    expect(fakeApi.lastCreateRequest?.items.length, 2);
    expect(find.byKey(const Key('counter-sales-confirm-cash')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('counter-sales-confirm-cash')));
    await tester.tap(find.byKey(const Key('counter-sales-confirm-cash')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('counter-sales-cash-note')),
      'Paiement reçu',
    );
    await tester.tap(
      find.byKey(const Key('counter-sales-cash-confirm-dialog-submit')),
    );
    await tester.pumpAndSettle();

    expect(fakeApi.confirmCalls, 1);
    expect(fakeApi.lastConfirmedReservationId, 'reservation-1');
    expect(find.text('Paiement confirmé avec succès.'), findsOneWidget);
  });
}

Future<void> _selectServiceClass(WidgetTester tester, String value) async {
  final serviceClassFinder =
      find.byKey(const Key('counter-sales-service-class'));
  await tester.ensureVisible(serviceClassFinder);
  await tester.tap(serviceClassFinder);
  await tester.pumpAndSettle();
  final menuLabel = value == 'ECONOMIE' ? 'ÉCONOMIE' : value;
  await tester.tap(find.text(menuLabel).last);
  await tester.pumpAndSettle();
}

class _FakeCounterApiService extends StationCounterApiService {
  int createCalls = 0;
  int confirmCalls = 0;
  StationCashSaleCreateRequest? lastCreateRequest;
  String? lastConfirmedReservationId;

  @override
  Future<StationCashSaleCreateResponse> createCashReservation(
    StationCashSaleCreateRequest request,
  ) async {
    createCalls += 1;
    lastCreateRequest = request;
    return StationCashSaleCreateResponse.fromJson({
      'reservation': _reservationJson,
      'expires_at': '2026-07-21T10:00:00Z',
      'total_amount': '14000.00',
      'currency': 'XOF',
      'item_count': request.items.length,
      'can_confirm_cash': true,
    });
  }

  @override
  Future<StationCashConfirmResponse> confirmCashPayment(
    String reservationId, {
    String? note,
  }) async {
    confirmCalls += 1;
    lastConfirmedReservationId = reservationId;
    return StationCashConfirmResponse.fromJson({
      'already_paid': false,
      'reservation': _reservationJson,
      'payment': {
        'id': 'payment-1',
        'reference': 'PAY-001',
        'status': 'success',
        'method': 'cash',
        'provider': 'manual_validation',
        'amount': '14000.00',
        'currency': 'XOF',
      },
      'tickets': [
        {
          'id': 'ticket-1',
          'reference': 'TCK-001',
          'status': 'issued',
          'amount': '7000.00',
          'currency': 'XOF',
        },
      ],
    });
  }
}

class _FakeOperationalApiService
    extends StationOperationalDeparturesApiService {
  @override
  Future<StationOperationalDeparturesResponse> getOperationalDepartures({
    DateTime? date,
    int page = 1,
    int pageSize = 20,
    List<String>? statuses,
    String? serviceClassId,
    String? search,
  }) async {
    return const StationOperationalDeparturesResponse(
      date: null,
      generatedAt: null,
      station:
          StationOperationalStation(id: 'station-1', name: 'Gare Yopougon'),
      summary: StationOperationalSummary(
        departuresTotal: 0,
        departuresScheduled: 0,
        departuresOpen: 0,
        departuresClosed: 0,
        departuresDeparted: 0,
        departuresCancelled: 0,
        travelersExpected: 0,
        ticketsActive: 0,
        ticketsChecked: 0,
        ticketsRemaining: 0,
        boardingRate: 0,
        blockedSeats: 0,
        alertsTotal: 0,
      ),
      capabilities: StationOperationalCapabilities(
        canReadDepartures: false,
        canManageDepartures: false,
        canOpenBoarding: false,
        canReadManifest: false,
        canReadBoardingSummary: false,
      ),
      count: 0,
      next: null,
      previous: null,
      results: [],
    );
  }
}

class _FakeBoardingApiService extends StationBoardingApiService {
  @override
  Future<StationDeparture> getDepartureDetail({required String departureId}) {
    return Future.value(
      StationDeparture.fromJson({
        'id': departureId,
        'status': {'code': 'open', 'label': 'Ouvert'},
        'departure_date': '2026-07-21',
        'service_class': {'code': 'ECONOMIE', 'name': 'Economie'},
        'seats': {
          'total': 0,
          'available': 0,
          'held': 0,
          'reserved': 0,
          'blocked': 0,
        },
        'tickets': {
          'total': 0,
          'issued': 0,
          'used': 0,
          'cancelled': 0,
          'expired': 0,
        },
      }),
    );
  }
}

final _user = User(
  id: 'staff-1',
  lastname: 'Cashier',
  firstname: 'User',
  phoneNumber: '+2250700000000',
  userType: UserType.staff,
  internalProfile: const InternalProfile(
    id: 'profile-1',
    role: InternalRole.cashier,
    roleLabel: 'Caissier',
    station: InternalStationRef(id: 'station-1', name: 'Gare Yopougon'),
    counter:
        InternalCounterRef(id: 'counter-1', code: 'C1', label: 'Guichet 1'),
  ),
  scopes: const [
    'station.reservations.search',
    'station.reservations.read',
    'station.sales.cash',
    'station.tickets.read',
    'station.tickets.print',
  ],
);

const _reservationJson = {
  'id': 'reservation-1',
  'reference': 'RES-001',
  'status': 'pending_payment',
  'channel': 'station_counter',
  'total_amount': '14000.00',
  'currency': 'XOF',
  'items': [
    {
      'id': 'item-1',
      'departure': 'departure-1',
      'is_for_customer': true,
      'unit_price': '7000.00',
      'currency': 'XOF',
      'status': 'pending_payment',
    },
  ],
  'payments': [],
};
