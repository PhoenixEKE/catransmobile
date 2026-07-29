import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/models/operations/seat_layout.dart';
import 'package:catrans_app/models/operations/seat_layout_seat.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/departures/admin_departures_controller.dart';
import 'package:catrans_app/screens/staff/admin/operations/layouts/admin_seat_layouts_controller.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';

void main() {
  test('loads a seat layout and its generated seats from fakes', () async {
    final service = FakeAdminOperationsApiService(
      layoutsPage: PagedResult<AdminOperationRecord>(
        count: 1,
        next: null,
        previous: null,
        results: [
          AdminOperationRecord(
            id: 'layout-1',
            name: 'Plan A',
            isActive: true,
            raw: const {
              'description': 'Plan principal',
              'total_seats': 2,
              'active_seat_count': 2,
              'structure_locked': false,
              'created_at': '2026-07-21T00:00:00Z',
              'updated_at': '2026-07-21T00:00:00Z',
            },
          ),
        ],
      ),
      layoutDetail: AdminOperationRecord(
        id: 'layout-1',
        name: 'Plan A',
        isActive: true,
        raw: const {
          'description': 'Plan principal',
          'total_seats': 2,
          'active_seat_count': 2,
          'structure_locked': false,
          'created_at': '2026-07-21T00:00:00Z',
          'updated_at': '2026-07-21T00:00:00Z',
        },
      ),
      seatsPage: PagedResult<SeatLayoutSeat>(
        count: 2,
        next: null,
        previous: null,
        results: [
          SeatLayoutSeat(
            id: 'seat-1',
            seatLayout: SeatLayout(
              id: 'layout-1',
              name: 'Plan A',
              totalSeats: 2,
              createdAt: DateTime.parse('2026-07-21T00:00:00Z'),
              updatedAt: DateTime.parse('2026-07-21T00:00:00Z'),
            ),
            seatNumber: 1,
            rowNumber: 1,
            columnNumber: 1,
            seatType: SeatType.standard,
            displayLabel: '1',
            isSelectable: true,
            isWindow: true,
            createdAt: DateTime.parse('2026-07-21T00:00:00Z'),
            updatedAt: DateTime.parse('2026-07-21T00:00:00Z'),
          ),
          SeatLayoutSeat(
            id: 'seat-2',
            seatLayout: SeatLayout(
              id: 'layout-1',
              name: 'Plan A',
              totalSeats: 2,
              createdAt: DateTime.parse('2026-07-21T00:00:00Z'),
              updatedAt: DateTime.parse('2026-07-21T00:00:00Z'),
            ),
            seatNumber: 2,
            rowNumber: 1,
            columnNumber: 2,
            seatType: SeatType.standard,
            displayLabel: '2',
            isSelectable: true,
            isAisle: true,
            createdAt: DateTime.parse('2026-07-21T00:00:00Z'),
            updatedAt: DateTime.parse('2026-07-21T00:00:00Z'),
          ),
        ],
      ),
    );

    final controller = AdminSeatLayoutsController(apiService: service);
    await controller.initialize();

    expect(controller.seatLayoutsPage?.results.first.name, 'Plan A');
    expect(controller.selectedLayout?.id, 'layout-1');
    expect(controller.seatsPage?.results, isNotEmpty);
    expect(controller.seatsPage?.results.first.displayLabel, '1');
  });

  test('generates departures and refreshes from backend result', () async {
    final service = FakeAdminOperationsApiService();
    final controller = AdminDeparturesController(apiService: service);
    await controller.initialize();

    final result = await controller.generateDeparturesBatch(
      'template-1',
      const AdminDepartureDatesRequest(
        departureDates: ['2026-07-22', '2026-07-23'],
      ),
    );

    expect(result?.createdCount, 1);
    expect(result?.existingCount, 1);
    expect(result?.departures.length, 2);
    expect(controller.departuresPage?.results, isNotEmpty);
  });
}

class FakeAdminOperationsApiService extends AdminOperationsApiService {
  final PagedResult<AdminOperationRecord> layoutsPage;
  final AdminOperationRecord layoutDetail;
  final PagedResult<SeatLayoutSeat> seatsPage;

  FakeAdminOperationsApiService({
    PagedResult<AdminOperationRecord>? layoutsPage,
    AdminOperationRecord? layoutDetail,
    PagedResult<SeatLayoutSeat>? seatsPage,
  })  : layoutsPage = layoutsPage ??
            PagedResult<AdminOperationRecord>(
              count: 1,
              next: null,
              previous: null,
              results: [
                AdminOperationRecord(
                  id: 'layout-1',
                  name: 'Plan A',
                  isActive: true,
                  raw: const {},
                ),
              ],
            ),
        layoutDetail = layoutDetail ??
            AdminOperationRecord(
              id: 'layout-1',
              name: 'Plan A',
              isActive: true,
              raw: const {},
            ),
        seatsPage = seatsPage ??
            PagedResult<SeatLayoutSeat>(
              count: 0,
              next: null,
              previous: null,
              results: const [],
            ),
        super(apiClient: _testApiClient());

  @override
  Future<PagedResult<AdminOperationRecord>> listSeatLayouts({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    return layoutsPage;
  }

  @override
  Future<AdminOperationRecord> getSeatLayout(String id) async {
    return layoutDetail;
  }

  @override
  Future<PagedResult<SeatLayoutSeat>> listSeatLayoutSeats(
    String seatLayoutId, {
    String? query,
    String? seatType,
    bool? isActive,
    bool? isSelectable,
    String? ordering,
    int page = 1,
    int pageSize = 100,
  }) async {
    return seatsPage;
  }

  @override
  Future<PagedResult<AdminOperationRecord>> listDepartureTemplates({
    String? query,
    bool? isActive,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    return PagedResult<AdminOperationRecord>(
      count: 1,
      next: null,
      previous: null,
      results: [
        AdminOperationRecord(
          id: 'template-1',
          name: 'Template A',
          isActive: true,
          raw: const {},
        ),
      ],
    );
  }

  @override
  Future<PagedResult<AdminDeparture>> listAdminDepartures({
    String? stationId,
    String? routeId,
    String? serviceClassId,
    String? departureTemplateId,
    String? status,
    String? dateFrom,
    String? dateTo,
    String? ordering,
    int page = 1,
    int pageSize = 20,
  }) async {
    return PagedResult<AdminDeparture>(
      count: 1,
      next: null,
      previous: null,
      results: [AdminDeparture.fromJson(const {})],
    );
  }

  @override
  Future<AdminDepartureGenerationResult> generateDepartures(
    String templateId,
    AdminDepartureDatesRequest request,
  ) async {
    return AdminDepartureGenerationResult(
      createdCount: 1,
      existingCount: 1,
      departures: [
        AdminDepartureGenerationResultItem(
          departureDate: '2026-07-22',
          created: true,
          departure: AdminDeparture.fromJson(const {}),
        ),
        AdminDepartureGenerationResultItem(
          departureDate: '2026-07-23',
          created: false,
          departure: AdminDeparture.fromJson(const {}),
        ),
      ],
    );
  }
}

ApiClient _testApiClient() {
  return ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'https://test.invalid/api/v1/')),
  );
}
