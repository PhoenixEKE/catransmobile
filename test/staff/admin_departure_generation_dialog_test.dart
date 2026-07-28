import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_seat_class_zone_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departure_generation_dialog.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  testWidgets(
      'new Prestige flow creates capacity layout, zone, and generated dates',
      (tester) async {
    final operations = _FakeOperationsApiService();
    final transport = _FakeTransportApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showAdminDepartureGenerationDialog(
                    context: context,
                    templates: const [],
                    previewGeneration: operations.previewDepartures,
                    generateDepartures: operations.generateDepartures,
                    isSubmitting: false,
                    apiService: operations,
                    transportApiService: transport,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau départ'), findsOneWidget);
    await _enter(
        tester, const Key('admin-departure-layout-capacity-field'), '37');
    await _enter(tester, const Key('admin-departure-zone-start-field'), '11');
    await _enter(tester, const Key('admin-departure-zone-end-field'), '37');
    await _enter(
        tester, const Key('admin-departure-start-date-field'), '2026-08-03');
    await _enter(
        tester, const Key('admin-departure-end-date-field'), '2026-08-05');

    await _tapKey(tester, const Key('admin-departure-generate-submit'));
    await tester.pumpAndSettle();

    expect(operations.createdLayoutRequest?.capacity, 37);
    expect(transport.createdScheduleRequest?.stationId, 'station-1');
    expect(transport.createdScheduleRequest?.routeId, 'route-1');
    expect(transport.createdScheduleRequest?.serviceClassId, 'class-prestige');
    expect(operations.createdTemplateRequest?.scheduleId, 'schedule-1');
    expect(operations.createdTemplateRequest?.seatLayoutId, 'layout-created');
    expect(operations.replacedZonesTemplateId, 'template-created');
    expect(operations.replacedZones.single.serviceClassId, 'class-prestige');
    expect(operations.replacedZones.single.seatNumberStart, 11);
    expect(operations.replacedZones.single.seatNumberEnd, 37);
    expect(operations.generatedTemplateId, 'template-created');
    expect(operations.generatedRequest?.departureDates, [
      '2026-08-03',
      '2026-08-04',
      '2026-08-05',
    ]);
    expect(find.textContaining('Créés: 3'), findsOneWidget);
  });
}

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.enterText(finder, text);
  await tester.pump();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

class _FakeOperationsApiService extends AdminOperationsApiService {
  AdminSeatLayoutWriteRequest? createdLayoutRequest;
  AdminDepartureTemplateWriteRequest? createdTemplateRequest;
  String? replacedZonesTemplateId;
  List<AdminSeatClassZoneDraft> replacedZones = const [];
  String? generatedTemplateId;
  AdminDepartureDatesRequest? generatedRequest;

  _FakeOperationsApiService() : super(apiClient: _testApiClient());

  @override
  Future<PagedResult<AdminOperationRecord>> listSeatLayouts({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    return const PagedResult(
      count: 0,
      next: null,
      previous: null,
      results: [],
    );
  }

  @override
  Future<AdminOperationRecord> createSeatLayout(
    AdminSeatLayoutWriteRequest request,
  ) async {
    createdLayoutRequest = request;
    return AdminOperationRecord(
      id: 'layout-created',
      name: request.name,
      isActive: true,
      raw: {'total_seats': request.capacity},
    );
  }

  @override
  Future<AdminOperationRecord> createDepartureTemplate(
    AdminDepartureTemplateWriteRequest request,
  ) async {
    createdTemplateRequest = request;
    return const AdminOperationRecord(
      id: 'template-created',
      name: 'Gare Test · Prestige · 08:00',
      isActive: true,
      raw: {
        'station': {'id': 'station-1', 'name': 'Gare Test'},
        'route': {'id': 'route-1', 'label': 'Gare Test -> Bouake'},
        'service_class': {
          'id': 'class-prestige',
          'code': 'PRESTIGE',
          'name': 'Prestige',
        },
        'departure_time': '08:00',
      },
    );
  }

  @override
  Future<List<AdminSeatClassZone>> replaceSeatClassZones(
    String templateId,
    List<AdminSeatClassZoneDraft> zones,
  ) async {
    replacedZonesTemplateId = templateId;
    replacedZones = zones;
    return const [];
  }

  @override
  Future<Map<String, dynamic>> previewDepartures(
    String templateId,
    AdminDepartureDatesRequest request,
  ) async {
    return {
      'results': request.departureDates
          .map((date) => {
                'departure_date': date,
                'valid': true,
                'already_exists': false,
              })
          .toList(),
    };
  }

  @override
  Future<AdminDepartureGenerationResult> generateDepartures(
    String templateId,
    AdminDepartureDatesRequest request,
  ) async {
    generatedTemplateId = templateId;
    generatedRequest = request;
    return AdminDepartureGenerationResult(
      createdCount: request.departureDates.length,
      existingCount: 0,
      departures: request.departureDates
          .map(
            (date) => AdminDepartureGenerationResultItem(
              departureDate: date,
              created: true,
              departure: AdminDeparture(
                id: 'departure-$date',
                departureDate: date,
                status: const AdminDepartureStatus(
                  code: 'scheduled',
                  label: 'Prévu',
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FakeTransportApiService extends AdminTransportBaseApiService {
  AdminScheduleCreateRequest? createdScheduleRequest;

  _FakeTransportApiService() : super(apiClient: _testApiClient());

  @override
  Future<PagedResult<AdminStation>> listStations({
    String? query,
    String? companyId,
    String? cityId,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_station],
    );
  }

  @override
  Future<PagedResult<AdminRoute>> listRoutes({
    String? query,
    String? companyId,
    String? departureStationId,
    String? departureCityId,
    String? destinationCityId,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_route],
    );
  }

  @override
  Future<PagedResult<AdminServiceClass>> listServiceClasses({
    String? query,
    bool? allowsSeatSelection,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_prestigeClass],
    );
  }

  @override
  Future<PagedResult<AdminSchedule>> listSchedules({
    String? query,
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTime,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult(
      count: 0,
      next: null,
      previous: null,
      results: [],
    );
  }

  @override
  Future<AdminSchedule> createSchedule(
      AdminScheduleCreateRequest request) async {
    createdScheduleRequest = request;
    return const AdminSchedule(
      id: 'schedule-1',
      station: _stationRef,
      route: _routeRef,
      serviceClass: _prestigeRef,
      departureTime: '08:00:00',
      departureTimeRaw: '08:00',
      isActive: true,
      createdAt: '2026-07-21T08:00:00Z',
      updatedAt: '2026-07-21T08:00:00Z',
    );
  }
}

const _companyRef = AdminTransportCompanyRef(
  id: 'company-1',
  name: 'CA TRANS',
  code: 'CAT',
  isActive: true,
);

const _cityRef = AdminTransportCityRef(
  id: 'city-1',
  name: 'Abidjan',
  country: "Cote d'Ivoire",
  isActive: true,
);

const _stationRef = AdminTransportStationRef(
  id: 'station-1',
  name: 'Gare Test',
  cityName: 'Abidjan',
  isActive: true,
);

const _prestigeRef = AdminTransportServiceClassRef(
  id: 'class-prestige',
  code: 'PRESTIGE',
  name: 'Prestige',
  allowsSeatSelection: true,
  isActive: true,
);

const _routeRef = AdminTransportRouteRef(
  id: 'route-1',
  departureStation: _stationRef,
  destinationCity: _cityRef,
  destinationName: 'Bouake',
  isActive: true,
);

const _station = AdminStation(
  id: 'station-1',
  name: 'Gare Test',
  normalizedName: 'gare test',
  cityNameSnapshot: 'Abidjan',
  cityName: 'Abidjan',
  company: _companyRef,
  city: _cityRef,
  isActive: true,
  createdAt: '2026-07-21T08:00:00Z',
  updatedAt: '2026-07-21T08:00:00Z',
);

const _route = AdminRoute(
  id: 'route-1',
  company: _companyRef,
  departureStation: _stationRef,
  departureCity: _cityRef,
  destinationCity: _cityRef,
  destinationName: 'Bouake',
  isActive: true,
  createdAt: '2026-07-21T08:00:00Z',
  updatedAt: '2026-07-21T08:00:00Z',
);

const _prestigeClass = AdminServiceClass(
  id: 'class-prestige',
  code: 'PRESTIGE',
  name: 'Prestige',
  defaultLoyaltyPoints: 0,
  rewardThresholdPoints: 0,
  allowsSeatSelection: true,
  isActive: true,
  createdAt: '2026-07-21T08:00:00Z',
  updatedAt: '2026-07-21T08:00:00Z',
);

ApiClient _testApiClient() {
  return ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1/')),
  );
}
