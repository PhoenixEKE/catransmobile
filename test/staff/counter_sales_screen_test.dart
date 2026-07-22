import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
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
  testWidgets('manual UUID departure field is removed', (tester) async {
    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    expect(find.byKey(const Key('counter-sales-departure-id-field')),
        findsNothing);
    expect(
        find.byKey(const Key('counter-sales-departure-list')), findsOneWidget);
  });

  testWidgets('loads departures only when both scopes are present',
      (tester) async {
    final allowedApi = _FakeOperationalApiService(
      plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
    );
    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: allowedApi,
    );
    expect(allowedApi.callCount, 1);

    final deniedApi = _FakeOperationalApiService(
      plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
    );
    await _pumpSalesScreen(
      tester,
      user: _cashierWithoutDepartureReadUser,
      operationalApiService: deniedApi,
    );
    expect(deniedApi.callCount, 0);
  });

  testWidgets('displays human-readable departure information', (tester) async {
    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    expect(find.textContaining('Yopougon → Abobo'), findsWidgets);
    expect(find.textContaining('Ouvert'), findsWidgets);
    expect(find.textContaining('places disponibles'), findsWidgets);
    expect(find.textContaining('Gare Yopougon → Abobo'), findsWidgets);
  });

  testWidgets('selects a departure visually and uses exactly its id in payload',
      (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key(
          'counter-sales-departure-card-aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')),
    );

    await _addSecondTravelerWithIdentity(tester);
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-0-seat-number')),
      '1',
    );
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-1-seat-number')),
      '2',
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    expect(counterApi.createCalls, 1);
    expect(
      counterApi.lastCreateRequest?.departureId,
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    );
  });

  testWidgets('without station.departures.read scope sale is blocked',
      (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithoutDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    expect(find.byKey(const Key('counter-sales-departure-scope-blocked')),
        findsOneWidget);

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    final createReservationButton =
        find.byKey(const Key('counter-sales-create-reservation'));
    expect(createReservationButton, findsOneWidget);
    await tester.ensureVisible(createReservationButton);
    await tester.pump();

    final createButton = tester.widget<ElevatedButton>(createReservationButton);
    if (createButton.onPressed != null) {
      await _ensureVisibleAndTap(tester, createReservationButton);
      expect(find.textContaining('La vente est bloquée'), findsOneWidget);
    } else {
      expect(find.textContaining('La vente est bloquée'), findsOneWidget);
    }

    expect(counterApi.createCalls, 0);
    expect(find.textContaining('La vente est bloquée'), findsOneWidget);
  });

  testWidgets('shows empty state when no sellable departure is available',
      (tester) async {
    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithNoOpen)],
      ),
    );

    expect(
      find.text('Aucun départ vendable ouvert pour votre gare actuellement.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error then retry loads departures', (tester) async {
    final api = _FakeOperationalApiService(
      plans: [
        _OperationalPlan.error(ApiException(message: 'Erreur chargement')),
        _OperationalPlan.response(_responseWithMixedStatuses),
      ],
    );

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: api,
    );

    expect(
        find.byKey(const Key('counter-sales-departure-retry')), findsOneWidget);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-departure-retry')),
    );

    expect(api.callCount, 2);
    expect(
        find.byKey(const Key('counter-sales-departure-list')), findsOneWidget);
  });

  testWidgets('non-sellable departures are not selectable', (tester) async {
    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    expect(find.textContaining('1 départ(s) masqué(s)'), findsOneWidget);
    expect(
      find.byKey(const Key(
          'counter-sales-departure-card-bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')),
      findsNothing,
    );
  });

  testWidgets('changing departure before create resets incompatible class data',
      (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
      boardingApiService: _FakeBoardingApiService(
        serviceClassByDepartureId: const {
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa': 'PRESTIGE',
          'cccccccc-cccc-4ccc-8ccc-cccccccccccc': 'ECONOMIE',
        },
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key(
          'counter-sales-departure-card-aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')),
    );

    await _addSecondTravelerWithIdentity(tester);
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-0-seat-number')),
      '3',
    );
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-1-seat-number')),
      '5',
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key(
          'counter-sales-departure-card-cccccccc-cccc-4ccc-8ccc-cccccccccccc')),
    );

    expect(find.byKey(const Key('counter-sales-traveler-0-seat-number')),
        findsNothing);
    expect(find.byKey(const Key('counter-sales-traveler-1-seat-number')),
        findsNothing);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    expect(counterApi.createCalls, 1);
    expect(counterApi.lastCreateRequest?.serviceClassCode, 'ECONOMIE');
    for (final item in counterApi.lastCreateRequest?.items ?? const []) {
      expect(item.seatNumber, isNull);
    }
  });

  testWidgets('departure is locked after pending reservation creation',
      (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await _addSecondTravelerWithIdentity(tester);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    expect(find.byKey(const Key('counter-sales-reset-pending-sale')),
        findsOneWidget);

    final beforeTap = find.textContaining('Départ sélectionné:');
    expect(beforeTap, findsOneWidget);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key(
          'counter-sales-departure-card-aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')),
    );

    expect(find.textContaining('Départ sélectionné:'), findsOneWidget);
  });

  testWidgets('mobile 320x700 renders without overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 320,
            height: 700,
            child: CounterSalesScreen(
              user: _cashierWithDepartureReadUser,
              counterApiService: _FakeCounterApiService(),
              operationalApiService: _FakeOperationalApiService(
                plans: [_OperationalPlan.response(_responseWithMixedStatuses)],
              ),
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

  testWidgets('PRESTIGE flow still works with seat numbers', (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responsePrestigeOnly)],
      ),
      boardingApiService: _FakeBoardingApiService(
        serviceClassByDepartureId: const {
          'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa': 'PRESTIGE',
        },
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await _addSecondTravelerWithIdentity(tester);
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-0-seat-number')),
      '1',
    );
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-traveler-1-seat-number')),
      '2',
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    expect(counterApi.createCalls, 1);
    expect(counterApi.lastCreateRequest?.serviceClassCode, 'PRESTIGE');
    expect(counterApi.lastCreateRequest?.items[0].seatNumber, 1);
    expect(counterApi.lastCreateRequest?.items[1].seatNumber, 2);
  });

  testWidgets('ECONOMIE flow still works without seat number', (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseEconomyOnly)],
      ),
      boardingApiService: _FakeBoardingApiService(
        serviceClassByDepartureId: const {
          'cccccccc-cccc-4ccc-8ccc-cccccccccccc': 'ECONOMIE',
        },
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await _addSecondTravelerWithIdentity(tester);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    expect(counterApi.createCalls, 1);
    expect(counterApi.lastCreateRequest?.serviceClassCode, 'ECONOMIE');
    for (final item in counterApi.lastCreateRequest?.items ?? const []) {
      expect(item.seatNumber, isNull);
    }
  });

  testWidgets('cash confirmation flow remains functional', (tester) async {
    final counterApi = _FakeCounterApiService();

    await _pumpSalesScreen(
      tester,
      user: _cashierWithDepartureReadUser,
      counterApiService: counterApi,
      operationalApiService: _FakeOperationalApiService(
        plans: [_OperationalPlan.response(_responseEconomyOnly)],
      ),
      boardingApiService: _FakeBoardingApiService(
        serviceClassByDepartureId: const {
          'cccccccc-cccc-4ccc-8ccc-cccccccccccc': 'ECONOMIE',
        },
      ),
    );

    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-customer-id-field')),
      '11111111-1111-4111-8111-111111111111',
    );
    await _addSecondTravelerWithIdentity(tester);

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-create-reservation')),
    );

    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-confirm-cash')),
    );
    await tester.pumpAndSettle();
    await _ensureVisibleAndEnterText(
      tester,
      find.byKey(const Key('counter-sales-cash-note')),
      'Paiement reçu',
    );
    await _ensureVisibleAndTap(
      tester,
      find.byKey(const Key('counter-sales-cash-confirm-dialog-submit')),
    );
    await tester.pumpAndSettle();

    expect(counterApi.confirmCalls, 1);
    expect(counterApi.lastConfirmedReservationId, 'reservation-1');
    expect(find.text('Paiement confirmé avec succès.'), findsOneWidget);
  });
}

Future<void> _pumpSalesScreen(
  WidgetTester tester, {
  required User user,
  StationCounterApiService? counterApiService,
  StationOperationalDeparturesApiService? operationalApiService,
  StationBoardingApiService? boardingApiService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CounterSalesScreen(
          user: user,
          counterApiService: counterApiService ?? _FakeCounterApiService(),
          operationalApiService:
              operationalApiService ?? _FakeOperationalApiService(),
          stationBoardingApiService:
              boardingApiService ?? _FakeBoardingApiService(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _addSecondTravelerWithIdentity(WidgetTester tester) async {
  await _ensureVisibleAndTap(
    tester,
    find.byKey(const Key('counter-sales-add-traveler')),
  );

  await _ensureVisibleAndEnterText(
    tester,
    find.byKey(const Key('counter-sales-traveler-1-lastname')),
    'Kouadio',
  );
  await _ensureVisibleAndEnterText(
    tester,
    find.byKey(const Key('counter-sales-traveler-1-firstname')),
    'Eric',
  );
  await _ensureVisibleAndEnterText(
    tester,
    find.byKey(const Key('counter-sales-traveler-1-phone')),
    '0700000000',
  );
}

Future<void> _ensureVisibleAndTap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _ensureVisibleAndEnterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.enterText(finder, text);
  await tester.pump();
}

class _FakeCounterApiService extends StationCounterApiService {
  int createCalls = 0;
  int confirmCalls = 0;
  StationCashSaleCreateRequest? lastCreateRequest;
  String? lastConfirmedReservationId;

  _FakeCounterApiService() : super(apiClient: _buildTestApiClient());

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

class _OperationalPlan {
  final StationOperationalDeparturesResponse? response;
  final Object? error;

  const _OperationalPlan._({this.response, this.error});

  const _OperationalPlan.response(StationOperationalDeparturesResponse value)
      : this._(response: value);

  const _OperationalPlan.error(Object value) : this._(error: value);
}

class _FakeOperationalApiService
    extends StationOperationalDeparturesApiService {
  final List<_OperationalPlan> plans;
  int callCount = 0;

  _FakeOperationalApiService({this.plans = const []})
      : super(apiClient: _buildTestApiClient());

  @override
  Future<StationOperationalDeparturesResponse> getOperationalDepartures({
    DateTime? date,
    int page = 1,
    int pageSize = 20,
    List<String>? statuses,
    String? serviceClassId,
    String? search,
  }) async {
    callCount += 1;
    final index = callCount - 1;
    final plan = index < plans.length
        ? plans[index]
        : _OperationalPlan.response(_responseWithMixedStatuses);

    if (plan.error != null) {
      throw plan.error!;
    }

    return plan.response!;
  }
}

class _FakeBoardingApiService extends StationBoardingApiService {
  final Map<String, String> serviceClassByDepartureId;

  _FakeBoardingApiService({
    this.serviceClassByDepartureId = const {
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa': 'PRESTIGE',
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc': 'ECONOMIE',
    },
  }) : super(apiClient: _buildTestApiClient());

  @override
  Future<StationDeparture> getDepartureDetail({required String departureId}) {
    final serviceClassCode =
        serviceClassByDepartureId[departureId] ?? 'ECONOMIE';
    return Future.value(
      StationDeparture.fromJson({
        'id': departureId,
        'status': {'code': 'open', 'label': 'Ouvert'},
        'departure_date': '2026-07-21',
        'service_class': {'code': serviceClassCode, 'name': serviceClassCode},
        'seats': {
          'total': 20,
          'available': 8,
          'held': 0,
          'reserved': 12,
          'blocked': 0,
        },
        'tickets': {
          'total': 12,
          'issued': 12,
          'used': 0,
          'cancelled': 0,
          'expired': 0,
        },
      }),
    );
  }
}

final _cashierWithDepartureReadUser = User(
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
  scopes: [
    'station.departures.read',
    'station.reservations.search',
    'station.reservations.read',
    'station.sales.cash',
    'station.tickets.read',
    'station.tickets.print',
  ],
);

final _cashierWithoutDepartureReadUser = User(
  id: 'staff-2',
  lastname: 'Cashier',
  firstname: 'NoScope',
  phoneNumber: '+2250700000001',
  userType: UserType.staff,
  internalProfile: const InternalProfile(
    id: 'profile-2',
    role: InternalRole.cashier,
    roleLabel: 'Caissier',
    station: InternalStationRef(id: 'station-1', name: 'Gare Yopougon'),
    counter:
        InternalCounterRef(id: 'counter-1', code: 'C1', label: 'Guichet 1'),
  ),
  scopes: [
    'station.reservations.search',
    'station.reservations.read',
    'station.sales.cash',
    'station.tickets.read',
    'station.tickets.print',
  ],
);

final _responseWithMixedStatuses = StationOperationalDeparturesResponse(
  date: null,
  generatedAt: null,
  station:
      const StationOperationalStation(id: 'station-1', name: 'Gare Yopougon'),
  summary: const StationOperationalSummary(
    departuresTotal: 3,
    departuresScheduled: 1,
    departuresOpen: 2,
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
  capabilities: const StationOperationalCapabilities(
    canReadDepartures: true,
    canManageDepartures: false,
    canOpenBoarding: false,
    canReadManifest: false,
    canReadBoardingSummary: false,
  ),
  count: 3,
  next: null,
  previous: null,
  results: [
    StationOperationalDeparture(
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '08:00:00',
      departureTimeRaw: '08:00',
      departureTimeDisplay: '08:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Abobo',
      routeName: 'Yopougon → Abobo',
      serviceClassId: 'economy',
      serviceClassName: 'ÉCONOMIE',
      status: 'open',
      statusLabel: 'Ouvert',
      travelersExpected: 10,
      ticketsActive: 10,
      ticketsChecked: 2,
      ticketsRemaining: 8,
      boardingRate: 20,
      validationRejections: 0,
      totalCapacity: 30,
      availableCapacity: 8,
      blockedSeats: 0,
      capacityMode: 'unassigned_capacity',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
    StationOperationalDeparture(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '09:00:00',
      departureTimeRaw: '09:00',
      departureTimeDisplay: '09:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Abidjan',
      routeName: 'Yopougon → Abidjan',
      serviceClassId: 'prestige',
      serviceClassName: 'PRESTIGE',
      status: 'open',
      statusLabel: 'Ouvert',
      travelersExpected: 7,
      ticketsActive: 7,
      ticketsChecked: 1,
      ticketsRemaining: 6,
      boardingRate: 14,
      validationRejections: 0,
      totalCapacity: 20,
      availableCapacity: 5,
      blockedSeats: 0,
      capacityMode: 'assigned_seats',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
    StationOperationalDeparture(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '10:00:00',
      departureTimeRaw: '10:00',
      departureTimeDisplay: '10:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Plateau',
      routeName: 'Yopougon → Plateau',
      serviceClassId: 'economy',
      serviceClassName: 'ÉCONOMIE',
      status: 'scheduled',
      statusLabel: 'Planifié',
      travelersExpected: 0,
      ticketsActive: 0,
      ticketsChecked: 0,
      ticketsRemaining: 0,
      boardingRate: 0,
      validationRejections: 0,
      totalCapacity: 25,
      availableCapacity: 25,
      blockedSeats: 0,
      capacityMode: 'unassigned_capacity',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
  ],
);

final _responseWithNoOpen = StationOperationalDeparturesResponse(
  date: null,
  generatedAt: null,
  station:
      const StationOperationalStation(id: 'station-1', name: 'Gare Yopougon'),
  summary: const StationOperationalSummary(
    departuresTotal: 1,
    departuresScheduled: 1,
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
  capabilities: const StationOperationalCapabilities(
    canReadDepartures: true,
    canManageDepartures: false,
    canOpenBoarding: false,
    canReadManifest: false,
    canReadBoardingSummary: false,
  ),
  count: 1,
  next: null,
  previous: null,
  results: [
    StationOperationalDeparture(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '10:00:00',
      departureTimeRaw: '10:00',
      departureTimeDisplay: '10:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Plateau',
      routeName: 'Yopougon → Plateau',
      serviceClassId: 'economy',
      serviceClassName: 'ÉCONOMIE',
      status: 'scheduled',
      statusLabel: 'Planifié',
      travelersExpected: 0,
      ticketsActive: 0,
      ticketsChecked: 0,
      ticketsRemaining: 0,
      boardingRate: 0,
      validationRejections: 0,
      totalCapacity: 20,
      availableCapacity: 20,
      blockedSeats: 0,
      capacityMode: 'unassigned_capacity',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
  ],
);

final _responsePrestigeOnly = StationOperationalDeparturesResponse(
  date: null,
  generatedAt: null,
  station:
      const StationOperationalStation(id: 'station-1', name: 'Gare Yopougon'),
  summary: const StationOperationalSummary(
    departuresTotal: 1,
    departuresScheduled: 0,
    departuresOpen: 1,
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
  capabilities: const StationOperationalCapabilities(
    canReadDepartures: true,
    canManageDepartures: false,
    canOpenBoarding: false,
    canReadManifest: false,
    canReadBoardingSummary: false,
  ),
  count: 1,
  next: null,
  previous: null,
  results: [
    StationOperationalDeparture(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '09:00:00',
      departureTimeRaw: '09:00',
      departureTimeDisplay: '09:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Abidjan',
      routeName: 'Yopougon → Abidjan',
      serviceClassId: 'prestige',
      serviceClassName: 'PRESTIGE',
      status: 'open',
      statusLabel: 'Ouvert',
      travelersExpected: 0,
      ticketsActive: 0,
      ticketsChecked: 0,
      ticketsRemaining: 0,
      boardingRate: 0,
      validationRejections: 0,
      totalCapacity: 18,
      availableCapacity: 6,
      blockedSeats: 0,
      capacityMode: 'assigned_seats',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
  ],
);

final _responseEconomyOnly = StationOperationalDeparturesResponse(
  date: null,
  generatedAt: null,
  station:
      const StationOperationalStation(id: 'station-1', name: 'Gare Yopougon'),
  summary: const StationOperationalSummary(
    departuresTotal: 1,
    departuresScheduled: 0,
    departuresOpen: 1,
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
  capabilities: const StationOperationalCapabilities(
    canReadDepartures: true,
    canManageDepartures: false,
    canOpenBoarding: false,
    canReadManifest: false,
    canReadBoardingSummary: false,
  ),
  count: 1,
  next: null,
  previous: null,
  results: [
    StationOperationalDeparture(
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      departureDate: DateTime(2026, 7, 21),
      departureTime: '08:00:00',
      departureTimeRaw: '08:00',
      departureTimeDisplay: '08:00',
      stationName: 'Gare Yopougon',
      destinationName: 'Abobo',
      routeName: 'Yopougon → Abobo',
      serviceClassId: 'economy',
      serviceClassName: 'ÉCONOMIE',
      status: 'open',
      statusLabel: 'Ouvert',
      travelersExpected: 0,
      ticketsActive: 0,
      ticketsChecked: 0,
      ticketsRemaining: 0,
      boardingRate: 0,
      validationRejections: 0,
      totalCapacity: 30,
      availableCapacity: 8,
      blockedSeats: 0,
      capacityMode: 'unassigned_capacity',
      alertsCount: 0,
      alerts: [],
      openedAt: null,
      openedByName: null,
      closedAt: null,
      closedByName: null,
      departedAt: null,
      departedByName: null,
      availableActions: const StationOperationalDepartureActions(
        canOpen: false,
        canClose: false,
        canMarkDeparted: false,
        canOpenBoarding: false,
        canViewManifest: false,
        canViewSummary: false,
      ),
      nextAction: null,
    ),
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

ApiClient _buildTestApiClient() {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://test.invalid/api/v1/',
      ),
    ),
  );
}
