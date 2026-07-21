import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/counters/admin_counters_screen.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin counters screen', () {
    testWidgets('requires station selection when no station exists', (
      tester,
    ) async {
      await pumpCounters(
        tester,
        canManage: true,
        apiService: _FakeTransportService(
          stations: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Sélectionnez une gare'),
        findsOneWidget,
      );
    });

    testWidgets('loads station scoped counters', (tester) async {
      final service = _FakeTransportService();

      await pumpCounters(
        tester,
        canManage: true,
        apiService: service,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('admin-counter-station-selector'),
        ),
        findsOneWidget,
      );
      expect(service.lastStationId, 'station-1');
      expect(find.text('G01'), findsOneWidget);
    });

    testWidgets('read only hides mutations and manage shows them', (
      tester,
    ) async {
      await pumpCounters(
        tester,
        canManage: false,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nouveau guichet'), findsNothing);
      expect(
        find.byKey(const Key('admin-counter-edit-counter-1')),
        findsNothing,
      );

      await pumpCounters(
        tester,
        canManage: true,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-counter-create')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('admin-counter-edit-counter-1')),
        findsOneWidget,
      );
    });

    testWidgets(
      'search filters ordering pagination and no station_id body',
      (tester) async {
        final service = _FakeTransportService(next: 'next');

        await pumpCounters(
          tester,
          canManage: true,
          apiService: service,
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          ' g01 ',
        );
        await tester.tap(find.byTooltip('Rechercher'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tous').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Actifs').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Par défaut').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Libellé A-Z').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Page suivante'));
        await tester.pumpAndSettle();

        expect(service.lastQuery, 'g01');
        expect(service.lastIsActive, isTrue);
        expect(service.lastOrdering, 'label');
        expect(service.lastPage, 2);

        await tester.tap(
          find.byKey(const Key('admin-counter-create')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Code *'),
          'G02',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Libellé *'),
          'Guichet 02',
        );

        await tester.tap(find.text('Créer'));
        await tester.pumpAndSettle();

        expect(
          service.createPayloadHadStationId,
          isFalse,
        );
      },
    );

    testWidgets('detail and deactivate dependency error', (
      tester,
    ) async {
      final service = _FakeTransportService(
        throwOnDeactivate: true,
      );

      await pumpCounters(
        tester,
        canManage: true,
        apiService: service,
      );
      await tester.pumpAndSettle();

      final detailFinder = find.byKey(
        const Key('admin-counter-detail-counter-1'),
      );

      expect(detailFinder, findsOneWidget);

      final detailButton = tester.widget<IconButton>(
        detailFinder,
      );

      expect(detailButton.onPressed, isNotNull);
      detailButton.onPressed!.call();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-counter-detail-title')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      final deactivateFinder = find.byKey(
        const Key('admin-counter-deactivate-counter-1'),
      );

      expect(deactivateFinder, findsOneWidget);

      final deactivateButton = tester.widget<IconButton>(
        deactivateFinder,
      );

      expect(deactivateButton.onPressed, isNotNull);
      deactivateButton.onPressed!.call();

      await tester.pumpAndSettle();

      final confirmFinder = find.byKey(
        const Key('admin-counter-deactivate-confirm'),
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
          'Le guichet possède encore des caissiers actifs.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mobile selector remains usable', (tester) async {
      await pumpCounters(
        tester,
        surfaceSize: const Size(320, 700),
        canManage: true,
        apiService: _FakeTransportService(),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Contexte : Gare Yopougon'),
        findsOneWidget,
      );
      expect(
        find.text('Gare : Gare Yopougon'),
        findsOneWidget,
      );
    });
  });
}

Future<void> pumpCounters(
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
        body: AdminCountersScreen(
          canManage: canManage,
          apiService: apiService,
        ),
      ),
    ),
  );
}

class _FakeTransportService extends AdminTransportBaseApiService {
  final List<AdminStation> stations;
  final bool throwOnDeactivate;
  final String? next;

  String? lastStationId;
  String? lastQuery;
  bool? lastIsActive;
  String? lastOrdering;
  int? lastPage;
  bool createPayloadHadStationId = false;

  _FakeTransportService({
    this.stations = const [_station],
    this.throwOnDeactivate = false,
    this.next,
  }) : super(
          transport: _FailingTransport(),
        );

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
    return PagedResult<AdminStation>(
      count: stations.length,
      next: null,
      previous: null,
      results: stations,
    );
  }

  @override
  Future<PagedResult<AdminStationCounter>> listCounters({
    required String stationId,
    String? query,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    lastStationId = stationId;
    lastQuery = query;
    lastIsActive = isActive;
    lastOrdering = ordering;
    lastPage = page;

    return PagedResult<AdminStationCounter>(
      count: 1,
      next: next,
      previous: page != null && page > 1 ? 'previous' : null,
      results: const [_counter],
    );
  }

  @override
  Future<AdminStationCounter> getCounter(
    String counterId,
  ) async {
    return _counter;
  }

  @override
  Future<AdminStationCounter> createCounter({
    required String stationId,
    required AdminStationCounterCreateRequest request,
  }) async {
    lastStationId = stationId;
    createPayloadHadStationId = request.toJson().containsKey('station_id');

    return _counter;
  }

  @override
  Future<AdminStationCounter> updateCounter(
    String counterId,
    AdminStationCounterUpdateRequest request,
  ) async {
    return _counter;
  }

  @override
  Future<AdminStationCounter> activateCounter(
    String counterId,
  ) async {
    return _counter;
  }

  @override
  Future<AdminStationCounter> deactivateCounter(
    String counterId,
  ) async {
    if (throwOnDeactivate) {
      throw ApiException(
        message: 'Le guichet possède encore des caissiers actifs.',
        statusCode: 400,
        details: const {
          'code': 'transport_counter_has_active_cashiers',
          'detail': 'Le guichet possède encore des caissiers actifs.',
        },
      );
    }

    return _counter;
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

const _stationRef = AdminTransportStationRef(
  id: 'station-1',
  name: 'Gare Yopougon',
  code: 'YOP',
  cityName: 'Abidjan',
  isActive: true,
);

const _station = AdminStation(
  id: 'station-1',
  name: 'Gare Yopougon',
  normalizedName: 'gare yopougon',
  code: 'YOP',
  cityNameSnapshot: 'Abidjan',
  cityName: 'Abidjan',
  company: AdminTransportCompanyRef(
    id: 'company-1',
    name: 'CA TRANS',
    code: 'CAT',
    isActive: true,
  ),
  isActive: true,
  createdAt: '',
  updatedAt: '',
);

const _counter = AdminStationCounter(
  id: 'counter-1',
  station: _stationRef,
  code: 'G01',
  label: 'Guichet 01',
  isActive: true,
  createdAt: '',
  updatedAt: '',
);
