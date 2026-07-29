import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_dashboard_models.dart';
import 'package:catrans_app/screens/staff/admin/admin_dashboard_home_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/admin_dashboard_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_metric_card.dart';

void main() {
  group('admin dashboard home', () {
    testWidgets('chargement réussi des quatre sections', (tester) async {
      final api = _FakeAdminDashboardApiService();

      await _pumpDashboard(tester, apiService: api);

      expect(api.overviewCalls, 1);
      expect(api.salesCalls, 1);
      expect(api.revenueCalls, 1);
      expect(api.topRoutesCalls, 1);
      expect(find.byKey(const Key('admin-dashboard-sales-section')),
          findsOneWidget);
      expect(find.byKey(const Key('admin-dashboard-revenue-section')),
          findsOneWidget);
      expect(find.byKey(const Key('admin-dashboard-top-routes-section')),
          findsOneWidget);
    });

    testWidgets('KPI réels affichés', (tester) async {
      final api = _FakeAdminDashboardApiService(
        overviewPlans: [
          _overviewResponse(
            reservationsTotal: 42,
            ticketsTotal: 31,
            departuresTotal: 6,
            revenue: '14000.00',
          ),
        ],
      );

      await _pumpDashboard(tester, apiService: api);

      final metricCards = find.byType(StaffMetricCard);

      expect(metricCards, findsNWidgets(4));
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('Réservations'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('Tickets'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('Départs'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('42'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('31'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: metricCards,
          matching: find.text('6'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('revenu XOF correctement formaté', (tester) async {
      final api = _FakeAdminDashboardApiService(
        overviewPlans: [_overviewResponse(revenue: '14000.00')],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(find.textContaining('XOF'), findsWidgets);
      expect(find.textContaining('14'), findsWidgets);
    });

    testWidgets('changement de date recharge les données', (tester) async {
      final api = _FakeAdminDashboardApiService();
      var nextDate = DateTime(2026, 7, 22);

      Future<DateTime?> pickDate(BuildContext _, DateTime __) async => nextDate;

      await _pumpDashboard(
        tester,
        apiService: api,
        datePicker: pickDate,
      );

      await tester.tap(find.byKey(const Key('admin-dashboard-date-button')));
      await tester.pumpAndSettle();

      expect(api.overviewCalls, 2);
      expect(api.salesCalls, 2);
      expect(api.revenueCalls, 2);
      expect(api.topRoutesCalls, 2);
      expect(api.salesDates.last, DateTime(2026, 7, 22));
      expect(api.revenueDates.last, DateTime(2026, 7, 22));
      expect(api.topRoutesDates.last, DateTime(2026, 7, 22));
    });

    testWidgets('bouton actualiser recharge les données', (tester) async {
      final api = _FakeAdminDashboardApiService();

      await _pumpDashboard(tester, apiService: api);

      await tester.tap(find.byKey(const Key('admin-dashboard-refresh-button')));
      await tester.pumpAndSettle();

      expect(api.overviewCalls, 2);
      expect(api.salesCalls, 2);
      expect(api.revenueCalls, 2);
      expect(api.topRoutesCalls, 2);
    });

    testWidgets('erreur overview affiche StaffErrorState', (tester) async {
      final api = _FakeAdminDashboardApiService(
        overviewPlans: [ApiException(message: 'Erreur overview')],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(find.byKey(const Key('admin-dashboard-overview-error')),
          findsOneWidget);
      expect(find.textContaining('Erreur overview'), findsOneWidget);
    });

    testWidgets('retry après erreur overview', (tester) async {
      final api = _FakeAdminDashboardApiService(
        overviewPlans: [
          ApiException(message: 'Erreur overview'),
          _overviewResponse(),
        ],
      );

      await _pumpDashboard(tester, apiService: api);
      expect(find.byKey(const Key('admin-dashboard-overview-error')),
          findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(api.overviewCalls, 2);
      expect(find.byKey(const Key('admin-dashboard-overview-error')),
          findsNothing);
      expect(find.byKey(const Key('admin-dashboard-sales-section')),
          findsOneWidget);
    });

    testWidgets('erreur endpoint secondaire n’efface pas les KPI principaux',
        (tester) async {
      final api = _FakeAdminDashboardApiService(
        salesPlans: [ApiException(message: 'Erreur ventes')],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(find.text('Revenu encaissé'), findsOneWidget);
      expect(find.textContaining('Erreur ventes'), findsOneWidget);
    });

    testWidgets('ventes vides affichent un état vide', (tester) async {
      final api = _FakeAdminDashboardApiService(
        salesPlans: [_salesResponse(results: const [])],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(
          find.byKey(const Key('admin-dashboard-sales-empty')), findsOneWidget);
    });

    testWidgets('revenus vides affichent un état vide', (tester) async {
      final api = _FakeAdminDashboardApiService(
        revenuePlans: [_revenueResponse(results: const [])],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(find.byKey(const Key('admin-dashboard-revenue-empty')),
          findsOneWidget);
    });

    testWidgets('top trajets vide affiche un état vide', (tester) async {
      final api = _FakeAdminDashboardApiService(
        topRoutesPlans: [_topRoutesResponse(results: const [])],
      );

      await _pumpDashboard(tester, apiService: api);

      expect(find.byKey(const Key('admin-dashboard-top-routes-empty')),
          findsOneWidget);
    });

    testWidgets('dashboard mobile 320x700 sans overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminDashboardApiService();
      await _pumpDashboard(tester, apiService: api);

      expect(tester.takeException(), isNull);
      expect(find.text('Tableau admin'), findsOneWidget);
    });

    testWidgets('dashboard tablette', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminDashboardApiService();
      await _pumpDashboard(tester, apiService: api);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-dashboard-revenue-section')),
          findsOneWidget);
    });

    testWidgets('dashboard desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminDashboardApiService();
      await _pumpDashboard(tester, apiService: api);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-dashboard-sales-section')),
          findsOneWidget);
      expect(find.byKey(const Key('admin-dashboard-top-routes-section')),
          findsOneWidget);
    });

    testWidgets('utilisateur sans scope voit accès refusé', (tester) async {
      final api = _FakeAdminDashboardApiService();
      final noScopeUser = _buildAdminUser(scopes: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminDashboardHomeScreen(user: noScopeUser, apiService: api),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
      expect(api.overviewCalls, 0);
    });
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required _FakeAdminDashboardApiService apiService,
  AdminDashboardDatePicker? datePicker,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminDashboardHomeScreen(
          user: _buildAdminUser(),
          apiService: apiService,
          datePicker: datePicker,
          nowProvider: () => DateTime(2026, 7, 21, 10, 30),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

User _buildAdminUser({List<String> scopes = const ['admin.dashboard.read']}) {
  return User(
    id: 'admin-1',
    lastname: 'Admin',
    firstname: 'Dashboard',
    phoneNumber: '+2250700000000',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: const InternalProfile(
      id: 'profile-admin-1',
      role: InternalRole.admin,
      roleLabel: 'Administrateur',
    ),
    scopes: scopes,
  );
}

class _FakeAdminDashboardApiService extends AdminDashboardApiService {
  final List<Object> overviewPlans;
  final List<Object> salesPlans;
  final List<Object> revenuePlans;
  final List<Object> topRoutesPlans;

  int overviewCalls = 0;
  int salesCalls = 0;
  int revenueCalls = 0;
  int topRoutesCalls = 0;

  final List<DateTime?> overviewDates = [];
  final List<DateTime?> salesDates = [];
  final List<DateTime?> revenueDates = [];
  final List<DateTime?> topRoutesDates = [];

  _FakeAdminDashboardApiService({
    this.overviewPlans = const [],
    this.salesPlans = const [],
    this.revenuePlans = const [],
    this.topRoutesPlans = const [],
  }) : super(apiClient: _buildTestApiClient());

  @override
  Future<AdminDashboardOverviewResponse> getOverview({DateTime? date}) async {
    overviewCalls += 1;
    overviewDates.add(_strip(date));
    final plan = _readPlan(overviewPlans, overviewCalls, _overviewResponse());
    if (plan is Exception) throw plan;
    return plan as AdminDashboardOverviewResponse;
  }

  @override
  Future<AdminDashboardSalesByChannelResponse> getSalesByChannel({
    DateTime? date,
  }) async {
    salesCalls += 1;
    salesDates.add(_strip(date));
    final plan = _readPlan(salesPlans, salesCalls, _salesResponse());
    if (plan is Exception) throw plan;
    return plan as AdminDashboardSalesByChannelResponse;
  }

  @override
  Future<AdminDashboardRevenueByPaymentMethodResponse>
      getRevenueByPaymentMethod({
    DateTime? date,
  }) async {
    revenueCalls += 1;
    revenueDates.add(_strip(date));
    final plan = _readPlan(revenuePlans, revenueCalls, _revenueResponse());
    if (plan is Exception) throw plan;
    return plan as AdminDashboardRevenueByPaymentMethodResponse;
  }

  @override
  Future<AdminDashboardTopRoutesResponse> getTopRoutes({DateTime? date}) async {
    topRoutesCalls += 1;
    topRoutesDates.add(_strip(date));
    final plan =
        _readPlan(topRoutesPlans, topRoutesCalls, _topRoutesResponse());
    if (plan is Exception) throw plan;
    return plan as AdminDashboardTopRoutesResponse;
  }
}

Object _readPlan(List<Object> plans, int callNumber, Object fallback) {
  final index = callNumber - 1;
  if (index < plans.length) return plans[index];
  return fallback;
}

AdminDashboardOverviewResponse _overviewResponse({
  int reservationsTotal = 10,
  int ticketsTotal = 8,
  int departuresTotal = 3,
  String revenue = '14000.00',
}) {
  return AdminDashboardOverviewResponse.fromJson({
    'date': '2026-07-21',
    'reservations': {
      'today_total': reservationsTotal,
      'pending_payment': 2,
      'confirmed': 6,
      'cancelled': 2,
    },
    'payments': {
      'today_total': 9,
      'success': 7,
      'failed': 1,
      'pending': 1,
      'revenue': revenue,
      'currency': 'XOF',
    },
    'tickets': {
      'today_total': ticketsTotal,
      'issued': 6,
      'used': 1,
      'cancelled': 1,
    },
    'departures': {
      'today_total': departuresTotal,
      'scheduled': 1,
      'open': 1,
      'closed': 1,
      'departed': 0,
      'cancelled': 0,
    },
    'seats': {
      'today_total': 50,
      'available': 20,
      'held': 5,
      'reserved': 20,
      'blocked': 5,
    },
    'requests': {
      'pending_changes': 2,
      'pending_cancellations': 1,
    },
  });
}

AdminDashboardSalesByChannelResponse _salesResponse({
  List<Map<String, dynamic>> results = const [
    {'channel': 'station_counter', 'total': 6},
    {'channel': 'mobile', 'total': 4},
  ],
}) {
  return AdminDashboardSalesByChannelResponse.fromJson({
    'date': '2026-07-21',
    'results': results,
  });
}

AdminDashboardRevenueByPaymentMethodResponse _revenueResponse({
  List<Map<String, dynamic>> results = const [
    {
      'method': 'cash',
      'provider': 'manual_validation',
      'total_amount': '10000.00',
      'total_payments': 5,
    },
    {
      'method': 'wave',
      'provider': 'wave_ci',
      'total_amount': '4000.00',
      'total_payments': 2,
    },
  ],
}) {
  return AdminDashboardRevenueByPaymentMethodResponse.fromJson({
    'date': '2026-07-21',
    'currency': 'XOF',
    'results': results,
  });
}

AdminDashboardTopRoutesResponse _topRoutesResponse({
  List<Map<String, dynamic>> results = const [
    {
      'route_id': 'route-1',
      'destination': 'Yopougon → Abidjan',
      'total_tickets': 5,
      'revenue': '9000.00',
    },
    {
      'route_id': 'route-2',
      'destination': 'Yopougon → Bouake',
      'total_tickets': 3,
      'revenue': '5000.00',
    },
  ],
}) {
  return AdminDashboardTopRoutesResponse.fromJson({
    'date': '2026-07-21',
    'currency': 'XOF',
    'results': results,
  });
}

ApiClient _buildTestApiClient() {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://test.invalid/api/v1/',
      ),
    ),
  );
}

DateTime? _strip(DateTime? date) {
  if (date == null) return null;
  return DateTime(date.year, date.month, date.day);
}
