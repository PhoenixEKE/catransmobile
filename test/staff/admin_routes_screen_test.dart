import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_routes_screen.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  testWidgets('loading then empty state is deterministic', (tester) async {
    final started = Completer<void>();
    final result = Completer<PagedResult<AdminRoute>>();

    await pumpRoutes(tester,
        apiService: _FakeTransportService(
            routeStarted: started, routeCompleter: result));
    await tester.pump();
    await started.future;
    await tester.pump();

    expect(find.text('Chargement des routes...'), findsOneWidget);

    result.complete(const PagedResult<AdminRoute>(
        count: 0, next: null, previous: null, results: []));
    await tester.pumpAndSettle();

    expect(find.text('Aucune route'), findsOneWidget);
  });

  testWidgets('read only hides route mutation actions', (tester) async {
    await pumpRoutes(
      tester,
      canManage: false,
      apiService: _FakeTransportService(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gare Yopougon'), findsOneWidget);
    expect(find.text('Bouake'), findsOneWidget);
    expect(find.byKey(const Key('admin-route-create')), findsNothing);
    expect(find.byKey(const Key('admin-route-edit-route-1')), findsNothing);
  });

  testWidgets('manage shows route mutation actions', (tester) async {
    await pumpRoutes(
      tester,
      canManage: true,
      apiService: _FakeTransportService(),
      rootKey: 'manage',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-route-create')), findsOneWidget);
    expect(find.byKey(const Key('admin-route-edit-route-1')), findsOneWidget);
  });

  testWidgets('deactivate dependency error is shown', (tester) async {
    final service = _FakeTransportService(throwOnDeactivate: true);
    await pumpRoutes(tester, canManage: true, apiService: service);
    await tester.pumpAndSettle();

    final finder = find.byKey(const Key('admin-route-deactivate-route-1'));
    expect(finder, findsOneWidget);
    final button = tester.widget<IconButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await tester.pumpAndSettle();

    final confirmFinder =
        find.byKey(const Key('admin-route-deactivate-confirm'));
    expect(confirmFinder, findsOneWidget);
    final confirm = tester.widget<ButtonStyleButton>(confirmFinder);
    expect(confirm.onPressed, isNotNull);
    confirm.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('La ligne possède encore des dépendances actives.'),
        findsOneWidget);
  });

  testWidgets('mobile cards render route context', (tester) async {
    await pumpRoutes(tester,
        surfaceSize: const Size(320, 700),
        canManage: true,
        apiService: _FakeTransportService());
    await tester.pumpAndSettle();

    expect(find.text('Compagnie : CA TRANS'), findsOneWidget);
    expect(find.text('Destination : Bouake'), findsOneWidget);
  });
}

Future<void> pumpRoutes(WidgetTester tester,
    {required AdminTransportBaseApiService apiService,
    bool canManage = true,
    Size surfaceSize = const Size(1280, 900),
    String rootKey = 'routes'}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          key: ValueKey(rootKey),
          body: AdminRoutesScreen(
              canManage: canManage, apiService: apiService))));
}

class _FakeTransportService extends AdminTransportBaseApiService {
  final Completer<void>? routeStarted;
  final Completer<PagedResult<AdminRoute>>? routeCompleter;
  final bool throwOnDeactivate;
  _FakeTransportService(
      {this.routeStarted, this.routeCompleter, this.throwOnDeactivate = false})
      : super(transport: _FailingTransport());

  @override
  Future<PagedResult<AdminCompany>> listCompanies(
          {String? query,
          bool? isActive,
          String? ordering,
          int? page,
          int? pageSize}) async =>
      const PagedResult(
          count: 1, next: null, previous: null, results: [_company]);
  @override
  Future<PagedResult<AdminStation>> listStations(
          {String? query,
          String? companyId,
          String? cityId,
          bool? isActive,
          String? ordering,
          int? page,
          int? pageSize}) async =>
      const PagedResult(
          count: 1, next: null, previous: null, results: [_station]);
  @override
  Future<PagedResult<AdminCity>> listCities(
          {String? query,
          String? country,
          bool? isActive,
          String? ordering,
          int? page,
          int? pageSize}) async =>
      const PagedResult(
          count: 1, next: null, previous: null, results: [_destinationCity]);
  @override
  Future<PagedResult<AdminRoute>> listRoutes(
      {String? query,
      String? companyId,
      String? departureStationId,
      String? departureCityId,
      String? destinationCityId,
      bool? isActive,
      String? ordering,
      int? page,
      int? pageSize}) async {
    if (routeStarted != null && !routeStarted!.isCompleted) {
      routeStarted!.complete();
    }
    if (routeCompleter != null) {
      return routeCompleter!.future;
    }
    return const PagedResult(
        count: 1, next: null, previous: null, results: [_route]);
  }

  @override
  Future<AdminRoute> getRoute(String id) async => _route;
  @override
  Future<AdminRoute> createRoute(AdminRouteCreateRequest request) async =>
      _route;
  @override
  Future<AdminRoute> updateRoute(
          String id, AdminRouteUpdateRequest request) async =>
      _route;
  @override
  Future<AdminRoute> activateRoute(String id) async => _route;
  @override
  Future<AdminRoute> deactivateRoute(String id) async {
    if (throwOnDeactivate) {
      throw ApiException(
          message: 'La ligne possède encore des dépendances actives.',
          statusCode: 400,
          details: const {
            'code': 'transport_route_has_active_dependencies',
            'detail': 'La ligne possède encore des dépendances actives.'
          });
    }
    return _route;
  }
}

class _FailingTransport implements AdminTransportBaseApiTransport {
  @override
  Future<dynamic> get(String path,
          {Map<String, dynamic>? queryParameters}) async =>
      throw StateError('Unexpected GET $path');
  @override
  Future<dynamic> post(String path, {dynamic data}) async =>
      throw StateError('Unexpected POST $path');
  @override
  Future<dynamic> patch(String path, {dynamic data}) async =>
      throw StateError('Unexpected PATCH $path');
}

const _company = AdminCompany(
    id: 'company-1',
    name: 'CA TRANS',
    code: 'CAT',
    isActive: true,
    createdAt: '',
    updatedAt: '');
const _destinationCity = AdminCity(
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
    city: AdminTransportCityRef(
        id: 'city-1',
        name: 'Abidjan',
        country: "Côte d'Ivoire",
        isActive: true),
    isActive: true,
    createdAt: '',
    updatedAt: '');
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
    departureCity: AdminTransportCityRef(
        id: 'city-1',
        name: 'Abidjan',
        country: "Côte d'Ivoire",
        isActive: true),
    destinationCity: AdminTransportCityRef(
        id: 'city-2', name: 'Bouake', country: "Côte d'Ivoire", isActive: true),
    destinationName: 'Bouake',
    isActive: true,
    createdAt: '',
    updatedAt: '');
