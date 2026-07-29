import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedules_screen.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  testWidgets('loading then empty state is deterministic', (tester) async {
    final started = Completer<void>();
    final result = Completer<PagedResult<AdminSchedule>>();

    await pumpSchedules(tester,
        apiService: _FakeTransportService(
            scheduleStarted: started, scheduleCompleter: result));
    await tester.pump();
    await started.future;
    await tester.pump();

    expect(find.text('Chargement des horaires...'), findsOneWidget);

    result.complete(const PagedResult<AdminSchedule>(
        count: 0, next: null, previous: null, results: []));
    await tester.pumpAndSettle();

    expect(find.text('Aucun horaire'), findsOneWidget);
  });

  testWidgets('read only hides schedule mutation actions', (tester) async {
    await pumpSchedules(
      tester,
      canManage: false,
      apiService: _FakeTransportService(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gare Yopougon'), findsOneWidget);
    expect(find.text('08:00'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('admin-schedule-create')), findsNothing);
    expect(
        find.byKey(const Key('admin-schedule-edit-schedule-1')), findsNothing);
  });

  testWidgets('manage shows schedule mutation actions', (tester) async {
    await pumpSchedules(
      tester,
      canManage: true,
      apiService: _FakeTransportService(),
      rootKey: 'manage-schedules',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-schedule-create')), findsOneWidget);
    expect(find.byKey(const Key('admin-schedule-edit-schedule-1')),
        findsOneWidget);
  });

  testWidgets('deactivate dependency error is shown', (tester) async {
    final service = _FakeTransportService(throwOnDeactivate: true);
    await pumpSchedules(tester, canManage: true, apiService: service);
    await tester.pumpAndSettle();

    final finder =
        find.byKey(const Key('admin-schedule-deactivate-schedule-1'));
    expect(finder, findsOneWidget);
    final button = tester.widget<IconButton>(finder);
    expect(button.onPressed, isNotNull);
    button.onPressed!.call();
    await tester.pumpAndSettle();

    final confirmFinder =
        find.byKey(const Key('admin-schedule-deactivate-confirm'));
    expect(confirmFinder, findsOneWidget);
    final confirm = tester.widget<ButtonStyleButton>(confirmFinder);
    expect(confirm.onPressed, isNotNull);
    confirm.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Cet horaire est utilisé par un modèle de départ actif.'),
        findsOneWidget);
  });

  testWidgets('mobile cards render schedule context', (tester) async {
    await pumpSchedules(tester,
        surfaceSize: const Size(320, 700),
        canManage: true,
        apiService: _FakeTransportService());
    await tester.pumpAndSettle();

    expect(find.text('Gare : Gare Yopougon'), findsOneWidget);
    expect(find.text('Classe : Économie'), findsOneWidget);
    expect(find.text('Heure : 08:00'), findsOneWidget);
  });
}

Future<void> pumpSchedules(WidgetTester tester,
    {required AdminTransportBaseApiService apiService,
    bool canManage = true,
    Size surfaceSize = const Size(1280, 900),
    String rootKey = 'schedules'}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          key: ValueKey(rootKey),
          body: AdminSchedulesScreen(
              canManage: canManage, apiService: apiService))));
}

class _FakeTransportService extends AdminTransportBaseApiService {
  final Completer<void>? scheduleStarted;
  final Completer<PagedResult<AdminSchedule>>? scheduleCompleter;
  final bool throwOnDeactivate;

  _FakeTransportService({
    this.scheduleStarted,
    this.scheduleCompleter,
    this.throwOnDeactivate = false,
  }) : super(transport: _FailingTransport());

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
  Future<PagedResult<AdminSchedule>> listSchedules(
      {String? query,
      String? stationId,
      String? routeId,
      String? serviceClassId,
      String? departureTime,
      bool? isActive,
      String? ordering,
      int? page,
      int? pageSize}) async {
    if (scheduleStarted != null && !scheduleStarted!.isCompleted) {
      scheduleStarted!.complete();
    }
    if (scheduleCompleter != null) {
      return scheduleCompleter!.future;
    }
    return const PagedResult(
        count: 1, next: null, previous: null, results: [_schedule]);
  }

  @override
  Future<AdminSchedule> getSchedule(String id) async => _schedule;

  @override
  Future<AdminSchedule> createSchedule(
          AdminScheduleCreateRequest request) async =>
      _schedule;

  @override
  Future<AdminSchedule> updateSchedule(
          String id, AdminScheduleUpdateRequest request) async =>
      _schedule;

  @override
  Future<AdminSchedule> activateSchedule(String id) async => _schedule;

  @override
  Future<AdminSchedule> deactivateSchedule(String id) async {
    if (throwOnDeactivate) {
      throw ApiException(
          message: 'Cet horaire est utilisé par un modèle de départ actif.',
          statusCode: 400,
          details: const {
            'code': 'transport_schedule_has_active_template',
            'detail': 'Cet horaire est utilisé par un modèle de départ actif.'
          });
    }
    return _schedule;
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

const _companyRef = AdminTransportCompanyRef(
    id: 'company-1', name: 'CA TRANS', code: 'CAT', isActive: true);
const _cityRef = AdminTransportCityRef(
    id: 'city-1', name: 'Abidjan', country: 'CI', isActive: true);
const _destinationRef = AdminTransportCityRef(
    id: 'city-2', name: 'Bouake', country: 'CI', isActive: true);
const _stationRef = AdminTransportStationRef(
    id: 'station-1',
    name: 'Gare Yopougon',
    cityName: 'Abidjan',
    isActive: true);
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
const _schedule = AdminSchedule(
    id: 'schedule-1',
    station: _stationRef,
    route: AdminTransportRouteRef(
        id: 'route-1',
        departureStation: _stationRef,
        destinationCity: _destinationRef,
        destinationName: 'Bouake',
        isActive: true),
    serviceClass: AdminTransportServiceClassRef(
        id: 'class-1',
        code: 'ECONOMIE',
        name: 'Économie',
        allowsSeatSelection: false,
        isActive: true),
    departureTime: '08:00:00',
    departureTimeRaw: '08:00',
    routeNote: 'Direct',
    isActive: true,
    createdAt: '',
    updatedAt: '');
