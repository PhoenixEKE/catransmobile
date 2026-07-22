import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/fares/admin_fares_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/routes/admin_route_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/schedules/admin_schedule_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_screen.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('transport responsive ui', () {
    testWidgets('cities screen stays stable at 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(
        tester,
        child: AdminCitiesScreen(
            canManage: true, apiService: _FakeTransportService()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-cities-table-view')), findsNothing);
      expect(find.byKey(const Key('admin-cities-list-view')), findsOneWidget);
    });

    testWidgets('fares screen stays stable at 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(
        tester,
        child: AdminFaresScreen(
            canManage: true, apiService: _FakeTransportService()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-fares-list-view')), findsOneWidget);
    });

    testWidgets('service classes screen stays stable at 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(
        tester,
        child: AdminServiceClassesScreen(
            canManage: true, apiService: _FakeTransportService()),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-service-classes-list-view')),
          findsOneWidget);
    });

    testWidgets('route detail dialog shows loading before data',
        (tester) async {
      final completer = Completer<AdminRoute>();
      await _pumpScreen(
        tester,
        child: _DialogHost(
          openDialog: (context) => showAdminRouteDetailDialog(
            context: context,
            route: _routeSummary(),
            loadDetail: (_) => completer.future,
          ),
        ),
      );

      expect(find.text('Chargement de la route...'), findsOneWidget);
      completer.complete(_routeDetail());
      await tester.pumpAndSettle();
      expect(find.text('Informations route'), findsOneWidget);
    });

    testWidgets('schedule detail dialog is fullscreen on mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final completer = Completer<AdminSchedule>();
      await _pumpScreen(
        tester,
        child: _DialogHost(
          openDialog: (context) => showAdminScheduleDetailDialog(
            context: context,
            schedule: _scheduleSummary(),
            loadDetail: (_) => completer.future,
          ),
        ),
      );

      expect(find.text('Chargement de l’horaire...'), findsOneWidget);
      completer.complete(_scheduleDetail());
      await tester.pumpAndSettle();
      expect(find.text('Informations horaire'), findsOneWidget);
    });

    testWidgets('route detail dialog retry works after error', (tester) async {
      final completer = Completer<AdminRoute>();
      await _pumpScreen(
        tester,
        child: _DialogHost(
          openDialog: (context) => showAdminRouteDetailDialog(
            context: context,
            route: _routeSummary(),
            loadDetail: (_) => completer.future,
          ),
        ),
      );

      completer.completeError(Exception('boom'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Impossible de charger'), findsOneWidget);
    });
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
  await tester.pump();
}

class _DialogHost extends StatefulWidget {
  final Future<void> Function(BuildContext context) openDialog;

  const _DialogHost({required this.openDialog});

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.openDialog(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _FakeTransportService extends AdminTransportBaseApiService {
  _FakeTransportService() : super(apiClient: _buildTestApiClient());

  @override
  Future<PagedResult<AdminCity>> listCities({
    String? query,
    String? country,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_citySummary()],
    );
  }

  @override
  Future<PagedResult<AdminFare>> listFares({
    String? query,
    String? routeId,
    String? serviceClassId,
    String? currency,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_fareSummary()],
    );
  }

  @override
  Future<PagedResult<AdminServiceClass>> listServiceClasses({
    String? query,
    bool? isActive,
    bool? allowsSeatSelection,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_serviceClassSummary()],
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
    return PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [_routeSummary()],
    );
  }

  @override
  Future<AdminRoute> getRoute(String id) async => _routeDetail();

  @override
  Future<AdminSchedule> getSchedule(String id) async => _scheduleDetail();
}

AdminCity _citySummary() {
  return AdminCity.fromJson({
    'id': 'city-1',
    'name': 'Abidjan',
    'normalized_name': 'abidjan',
    'country': "Côte d'Ivoire",
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  });
}

AdminServiceClass _serviceClassSummary() {
  return AdminServiceClass.fromJson({
    'id': 'class-1',
    'code': 'ECONOMIE',
    'name': 'Économie',
    'default_loyalty_points': 0,
    'reward_threshold_points': 0,
    'allows_seat_selection': false,
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  });
}

AdminRoute _routeSummary() {
  return AdminRoute.fromJson({
    'id': 'route-1',
    'company': {
      'id': 'company-1',
      'name': 'CA TRANS',
      'code': 'CAT',
      'is_active': true,
    },
    'departure_station': {
      'id': 'station-1',
      'name': 'Gare Yopougon',
      'code': 'YOP',
      'city_name': 'Abidjan',
      'is_active': true,
    },
    'departure_city': {
      'id': 'city-1',
      'name': 'Abidjan',
      'country': "Côte d'Ivoire",
      'is_active': true,
    },
    'destination_city': {
      'id': 'city-2',
      'name': 'Bouake',
      'country': "Côte d'Ivoire",
      'is_active': true,
    },
    'destination_name': 'Bouake',
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  });
}

AdminRoute _routeDetail() => _routeSummary();

AdminFare _fareSummary() {
  return AdminFare.fromJson({
    'id': 'fare-1',
    'route': {
      'id': 'route-1',
      'departure_station': {
        'id': 'station-1',
        'name': 'Gare Yopougon',
        'code': 'YOP',
        'city_name': 'Abidjan',
        'is_active': true,
      },
      'destination_city': {
        'id': 'city-2',
        'name': 'Bouake',
        'country': "Côte d'Ivoire",
        'is_active': true,
      },
      'destination_name': 'Bouake',
      'is_active': true,
    },
    'service_class': {
      'id': 'class-1',
      'code': 'ECONOMIE',
      'name': 'Économie',
      'allows_seat_selection': false,
      'is_active': true,
    },
    'amount': '7000.00',
    'currency': 'XOF',
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  });
}

AdminSchedule _scheduleSummary() {
  return AdminSchedule.fromJson({
    'id': 'schedule-1',
    'station': {
      'id': 'station-1',
      'name': 'Gare Yopougon',
      'code': 'YOP',
      'city_name': 'Abidjan',
      'is_active': true,
    },
    'route': {
      'id': 'route-1',
      'departure_station': {
        'id': 'station-1',
        'name': 'Gare Yopougon',
        'code': 'YOP',
        'city_name': 'Abidjan',
        'is_active': true,
      },
      'destination_city': {
        'id': 'city-2',
        'name': 'Bouake',
        'country': "Côte d'Ivoire",
        'is_active': true,
      },
      'destination_name': 'Bouake',
      'is_active': true,
    },
    'service_class': {
      'id': 'class-1',
      'code': 'ECONOMIE',
      'name': 'Économie',
      'allows_seat_selection': false,
      'is_active': true,
    },
    'departure_time': '08:00:00',
    'departure_time_raw': '08:00',
    'route_note': 'Direct',
    'is_active': true,
    'created_at': '2026-07-20T08:00:00Z',
    'updated_at': '2026-07-20T09:00:00Z',
  });
}

AdminSchedule _scheduleDetail() => _scheduleSummary();

ApiClient _buildTestApiClient() {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://test.invalid/api/v1/',
      ),
    ),
  );
}
