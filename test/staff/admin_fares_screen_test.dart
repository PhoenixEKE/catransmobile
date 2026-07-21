import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_screen.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  testWidgets('loading then empty state is deterministic', (tester) async {
    final started = Completer<void>();
    final result = Completer<PagedResult<AdminFare>>();

    await pumpFares(tester,
        apiService:
            _FakeTransportService(fareStarted: started, fareCompleter: result));
    await tester.pump();
    await started.future;
    await tester.pump();

    expect(find.text('Chargement des tarifs...'), findsOneWidget);

    result.complete(const PagedResult<AdminFare>(
        count: 0, next: null, previous: null, results: []));
    await tester.pumpAndSettle();

    expect(find.text('Aucun tarif'), findsOneWidget);
  });

  testWidgets('read only hides mutations and manage shows replace',
      (tester) async {
    await pumpFares(tester,
        canManage: false, apiService: _FakeTransportService());
    await tester.pumpAndSettle();

    expect(find.text('7000.00 XOF'), findsOneWidget);
    expect(find.byKey(const Key('admin-fare-create')), findsNothing);
    expect(find.byKey(const Key('admin-fare-replace-fare-1')), findsNothing);

    await pumpFares(tester,
        canManage: true,
        apiService: _FakeTransportService(),
        rootKey: 'manage');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-fare-create')), findsOneWidget);
    expect(find.byKey(const Key('admin-fare-replace-fare-1')), findsOneWidget);
  });

  testWidgets(
      'replace action calls replace service and keeps no patch amount path',
      (tester) async {
    final service = _FakeTransportService();
    await pumpFares(tester, canManage: true, apiService: service);
    await tester.pumpAndSettle();

    final finder = find.byKey(const Key('admin-fare-replace-fare-1'));
    expect(finder, findsOneWidget);
    final button = tester.widget<IconButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nouveau montant *'), '8000');
    final confirm = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('admin-fare-replace-confirm')));
    expect(confirm.onPressed, isNotNull);
    confirm.onPressed!.call();
    await tester.pumpAndSettle();

    expect(service.replaceCalls, 1);
    expect(service.lastReplaceRequest?.toJson(),
        {'amount': '8000', 'currency': 'XOF'});
    expect(service.patchAmountAttempted, isFalse);
  });

  testWidgets('deactivate dependency error is shown', (tester) async {
    final service = _FakeTransportService(throwOnDeactivate: true);
    await pumpFares(tester, canManage: true, apiService: service);
    await tester.pumpAndSettle();

    final finder = find.byKey(const Key('admin-fare-deactivate-fare-1'));
    expect(finder, findsOneWidget);
    final button = tester.widget<IconButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await tester.pumpAndSettle();

    final confirm = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('admin-fare-deactivate-confirm')));
    expect(confirm.onPressed, isNotNull);
    confirm.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Un autre tarif actif existe déjà pour cette ligne.'),
        findsOneWidget);
  });
}

Future<void> pumpFares(WidgetTester tester,
    {required AdminTransportBaseApiService apiService,
    bool canManage = true,
    Size surfaceSize = const Size(1280, 900),
    String rootKey = 'fares'}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          key: ValueKey(rootKey),
          body:
              AdminFaresScreen(canManage: canManage, apiService: apiService))));
}

class _FakeTransportService extends AdminTransportBaseApiService {
  final Completer<void>? fareStarted;
  final Completer<PagedResult<AdminFare>>? fareCompleter;
  final bool throwOnDeactivate;
  int replaceCalls = 0;
  bool patchAmountAttempted = false;
  AdminFareReplaceRequest? lastReplaceRequest;
  _FakeTransportService(
      {this.fareStarted, this.fareCompleter, this.throwOnDeactivate = false})
      : super(transport: _FailingTransport());

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
          int? pageSize}) async =>
      const PagedResult(
          count: 1, next: null, previous: null, results: [_route]);
  @override
  Future<PagedResult<AdminServiceClass>> listServiceClasses(
          {String? query,
          bool? allowsSeatSelection,
          bool? isActive,
          String? ordering,
          int? page,
          int? pageSize}) async =>
      const PagedResult(
          count: 1, next: null, previous: null, results: [_serviceClass]);
  @override
  Future<PagedResult<AdminFare>> listFares(
      {String? query,
      String? routeId,
      String? serviceClassId,
      String? currency,
      bool? isActive,
      String? ordering,
      int? page,
      int? pageSize}) async {
    if (fareStarted != null && !fareStarted!.isCompleted) {
      fareStarted!.complete();
    }
    if (fareCompleter != null) {
      return fareCompleter!.future;
    }
    return const PagedResult(
        count: 1, next: null, previous: null, results: [_fare]);
  }

  @override
  Future<AdminFare> getFare(String id) async => _fare;
  @override
  Future<AdminFare> createFare(AdminFareCreateRequest request) async => _fare;
  @override
  Future<AdminFare> updateFare(String id, AdminFarePatchRequest request) async {
    if (request.toJson().containsKey('amount')) {
      patchAmountAttempted = true;
    }
    return _fare;
  }

  @override
  Future<AdminFare> replaceFare(
      String id, AdminFareReplaceRequest request) async {
    replaceCalls += 1;
    lastReplaceRequest = request;
    return _fare;
  }

  @override
  Future<AdminFare> activateFare(String id) async => _fare;
  @override
  Future<AdminFare> deactivateFare(String id) async {
    if (throwOnDeactivate) {
      throw ApiException(
          message: 'Un autre tarif actif existe déjà pour cette ligne.',
          statusCode: 400,
          details: const {
            'code': 'transport_duplicate_active_fare',
            'detail': 'Un autre tarif actif existe déjà pour cette ligne.'
          });
    }
    return _fare;
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
    updatedAt: '');
