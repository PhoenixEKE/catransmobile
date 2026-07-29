import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/stations/admin_stations_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin stations screen', () {
    testWidgets('denies access without scope from shell', (tester) async {
      await pumpHome(
        tester,
        user: _user(scopes: const []),
        apiService: _FakeTransportService(),
      );

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
    });

    testWidgets('read only hides mutations and manage shows them', (
      tester,
    ) async {
      await pumpStations(
        tester,
        canManage: false,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gare Yopougon'), findsOneWidget);
      expect(find.text('Nouvelle gare'), findsNothing);
      expect(
        find.byKey(const Key('admin-station-edit-station-1')),
        findsNothing,
      );

      await pumpStations(
        tester,
        canManage: true,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle gare'), findsOneWidget);
      expect(
        find.byKey(const Key('admin-station-edit-station-1')),
        findsOneWidget,
      );
    });

    testWidgets('loading and empty states', (tester) async {
      final stationsStarted = Completer<void>();
      final stationsResult = Completer<PagedResult<AdminStation>>();

      await pumpStations(
        tester,
        canManage: true,
        apiService: _FakeTransportService(
          stationListStarted: stationsStarted,
          stationListCompleter: stationsResult,
        ),
      );

      await tester.pump();
      await stationsStarted.future;
      expect(stationsStarted.isCompleted, isTrue);
      await tester.pump();

      expect(
        find.text('Chargement des gares...'),
        findsOneWidget,
      );

      stationsResult.complete(
        const PagedResult<AdminStation>(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune gare'), findsOneWidget);
    });

    testWidgets('filters ordering and pagination', (tester) async {
      final service = _FakeTransportService(next: 'next');

      await pumpStations(
        tester,
        canManage: true,
        apiService: service,
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), ' yop ');
      await tester.tap(find.byTooltip('Rechercher'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toutes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CA TRANS').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tous').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actives').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Par défaut').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Code A-Z').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Page suivante'));
      await tester.pumpAndSettle();

      expect(service.lastQuery, 'yop');
      expect(service.lastCompanyId, 'company-1');
      expect(service.lastIsActive, isTrue);
      expect(service.lastOrdering, 'code');
      expect(service.lastPage, 2);
    });

    testWidgets('detail and dependency error keep structured messages', (
      tester,
    ) async {
      final service = _FakeTransportService(
        throwOnStationDeactivate: true,
      );

      await pumpStations(
        tester,
        canManage: true,
        apiService: service,
      );
      await tester.pumpAndSettle();

      final detailFinder = find.byKey(
        const Key('admin-station-detail-station-1'),
      );

      expect(detailFinder, findsOneWidget);

      final detailButton = tester.widget<IconButton>(
        detailFinder,
      );

      expect(detailButton.onPressed, isNotNull);
      detailButton.onPressed!.call();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-station-detail-title')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      final deactivateFinder = find.byKey(
        const Key('admin-station-deactivate-station-1'),
      );

      expect(deactivateFinder, findsOneWidget);

      final deactivateButton = tester.widget<IconButton>(
        deactivateFinder,
      );

      expect(deactivateButton.onPressed, isNotNull);
      deactivateButton.onPressed!.call();

      await tester.pumpAndSettle();

      final confirmFinder = find.byKey(
        const Key('admin-station-deactivate-confirm'),
      );

      expect(confirmFinder, findsOneWidget);

      final confirmButton = tester.widget<ButtonStyleButton>(
        confirmFinder,
      );

      expect(confirmButton.onPressed, isNotNull);
      confirmButton.onPressed!.call();

      await tester.pumpAndSettle();

      expect(
        find.text(
          'La gare possède encore des dépendances actives.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mobile cards render without overflow-prone table', (
      tester,
    ) async {
      await pumpStations(
        tester,
        surfaceSize: const Size(320, 700),
        canManage: true,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Compagnie : CA TRANS'),
        findsOneWidget,
      );
    });
  });
}

Future<void> pumpHome(
  WidgetTester tester, {
  required User user,
  required AdminTransportBaseApiService apiService,
}) async {
  await tester.binding.setSurfaceSize(
    const Size(1280, 900),
  );

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: ValueKey(apiService),
        body: AdminTransportHomeScreen(
          user: user,
          apiService: apiService,
        ),
      ),
    ),
  );
}

Future<void> pumpStations(
  WidgetTester tester, {
  required bool canManage,
  required AdminTransportBaseApiService apiService,
  Size surfaceSize = const Size(1280, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);

  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: ValueKey(apiService),
        body: AdminStationsScreen(
          canManage: canManage,
          apiService: apiService,
        ),
      ),
    ),
  );
}

User _user({
  required List<String> scopes,
}) {
  return User(
    id: 'staff-1',
    lastname: 'Admin',
    firstname: 'Staff',
    phoneNumber: '+2250101010101',
    email: 'staff@catrans.test',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: const InternalProfile(
      id: 'profile-1',
      role: InternalRole.admin,
      roleLabel: 'Admin',
    ),
    scopes: scopes,
  );
}

class _FakeTransportService extends AdminTransportBaseApiService {
  final bool throwOnStationDeactivate;
  final String? next;
  final Completer<void>? stationListStarted;
  final Completer<PagedResult<AdminStation>>? stationListCompleter;

  String? lastQuery;
  String? lastCompanyId;
  bool? lastIsActive;
  String? lastOrdering;
  int? lastPage;

  _FakeTransportService({
    this.throwOnStationDeactivate = false,
    this.next,
    this.stationListStarted,
    this.stationListCompleter,
  }) : super(
          transport: _FailingTransport(),
        );

  @override
  Future<PagedResult<AdminCompany>> listCompanies({
    String? query,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult<AdminCompany>(
      count: 1,
      next: null,
      previous: null,
      results: [_company],
    );
  }

  @override
  Future<PagedResult<AdminCity>> listCities({
    String? query,
    String? country,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    return const PagedResult<AdminCity>(
      count: 1,
      next: null,
      previous: null,
      results: [_city],
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
  }) async {
    lastQuery = query;
    lastCompanyId = companyId;
    lastIsActive = isActive;
    lastOrdering = ordering;
    lastPage = page;

    if (stationListStarted != null && !stationListStarted!.isCompleted) {
      stationListStarted!.complete();
    }

    if (stationListCompleter != null) {
      return stationListCompleter!.future;
    }

    return PagedResult<AdminStation>(
      count: 1,
      next: next,
      previous: page != null && page > 1 ? 'previous' : null,
      results: const [_station],
    );
  }

  @override
  Future<AdminStation> getStation(String id) async {
    return _station;
  }

  @override
  Future<AdminStation> createStation(
    AdminStationCreateRequest request,
  ) async {
    return _station;
  }

  @override
  Future<AdminStation> updateStation(
    String id,
    AdminStationUpdateRequest request,
  ) async {
    return _station;
  }

  @override
  Future<AdminStation> activateStation(String id) async {
    return _station;
  }

  @override
  Future<AdminStation> deactivateStation(String id) async {
    if (throwOnStationDeactivate) {
      throw ApiException(
        message: 'La gare possède encore des dépendances actives.',
        statusCode: 400,
        details: const {
          'code': 'transport_station_has_active_dependencies',
          'detail': 'La gare possède encore des dépendances actives.',
        },
      );
    }

    return _station;
  }
}

class _FailingTransport implements AdminTransportBaseApiTransport {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
  }) async {
    throw StateError('Unexpected POST $path');
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
  }) async {
    throw StateError('Unexpected PATCH $path');
  }
}

const _company = AdminCompany(
  id: 'company-1',
  name: 'CA TRANS',
  code: 'CAT',
  customerServicePhone: '+2250101010101',
  isActive: true,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T09:00:00Z',
);

const _city = AdminCity(
  id: 'city-1',
  name: 'Abidjan',
  normalizedName: 'abidjan',
  country: "Côte d'Ivoire",
  isActive: true,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T09:00:00Z',
);

const _station = AdminStation(
  id: 'station-1',
  name: 'Gare Yopougon',
  normalizedName: 'gare yopougon',
  code: 'YOP',
  phoneLine: '+2250101010101',
  representative: 'Awa',
  cityNameSnapshot: 'Abidjan',
  cityName: 'Abidjan',
  company: AdminTransportCompanyRef(
    id: 'company-1',
    name: 'CA TRANS',
    code: 'CAT',
    isActive: true,
  ),
  city: AdminTransportCityRef(
    id: 'city-1',
    name: 'Abidjan',
    country: "Côte d'Ivoire",
    isActive: true,
  ),
  isActive: true,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T09:00:00Z',
);
