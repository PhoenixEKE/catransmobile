import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_seat_class_zone_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_seat_class_zones_dialog.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  testWidgets('warns on reduction and displays backend conflict message',
      (tester) async {
    final operations = _FakeOperationsService();
    final transport = _FakeTransportService();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showAdminSeatClassZonesDialog(
                    context: context,
                    departureTemplateId: 'template-1',
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

    await tester.enterText(find.widgetWithText(TextFormField, 'De'), '15');
    await tester.pumpAndSettle();

    expect(find.textContaining('Cette modification réduit la plage'),
        findsOneWidget);
    expect(find.textContaining('11, 12, 13, 14'), findsOneWidget);

    operations.replaceError = ApiException(
      message: 'Conflit de réservations',
      statusCode: 400,
      details: const {
        'code': 'operations_zone_reduction_has_active_bookings',
        'detail':
            'La plage ne peut pas être réduite : siège(s) 11 déjà réservé(s).',
        'field': 'zones',
      },
    );
    final saveButton = find.widgetWithText(ElevatedButton, 'Enregistrer');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(operations.replaceCalls, 1);
    expect(
      find.textContaining('siège(s) 11 déjà réservé(s)', skipOffstage: false),
      findsOneWidget,
    );
  });
}

class _FakeOperationsService extends AdminOperationsApiService {
  ApiException? replaceError;
  int replaceCalls = 0;

  _FakeOperationsService() : super(apiClient: _testApiClient());

  @override
  Future<PagedResult<AdminSeatClassZone>> listSeatClassZones(
    String templateId, {
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 100,
  }) async {
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [
        AdminSeatClassZone(
          id: 'zone-1',
          serviceClass: AdminSeatClassZoneServiceClassRef(
            id: 'class-prestige',
            code: 'PRESTIGE',
            name: 'Prestige',
            isActive: true,
          ),
          seatNumberStart: 11,
          seatNumberEnd: 37,
          isActive: true,
        ),
      ],
    );
  }

  @override
  Future<List<AdminSeatClassZone>> replaceSeatClassZones(
    String templateId,
    List<AdminSeatClassZoneDraft> zones,
  ) async {
    replaceCalls++;
    final error = replaceError;
    if (error != null) throw error;
    return const [];
  }
}

class _FakeTransportService extends AdminTransportBaseApiService {
  _FakeTransportService() : super(apiClient: _testApiClient());

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
      results: [
        AdminServiceClass(
          id: 'class-prestige',
          code: 'PRESTIGE',
          name: 'Prestige',
          defaultLoyaltyPoints: 0,
          rewardThresholdPoints: 100,
          allowsSeatSelection: true,
          isActive: true,
          createdAt: '',
          updatedAt: '',
        ),
      ],
    );
  }

  @override
  Future<PagedResult<AdminStation>> listStations({
    String? query,
    String? companyId,
    String? cityId,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();
}

ApiClient _testApiClient() {
  return ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1/')),
  );
}
