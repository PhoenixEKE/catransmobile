import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/cities/admin_cities_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin cities screen', () {
    testWidgets('denies access without transport scope', (tester) async {
      await pumpHome(
        tester,
        user: _user(scopes: const []),
        apiService: _FakeTransportService(),
      );

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
    });

    testWidgets(
      'read scope shows list and hides mutation actions',
      (tester) async {
        await pumpHome(
          tester,
          user: _user(scopes: const ['admin.transport.read']),
          apiService: _FakeTransportService(),
        );

        await tester.pumpAndSettle();

        final citiesNavigation = find.text('Villes');
        expect(citiesNavigation, findsOneWidget);

        await tester.tap(citiesNavigation);
        await tester.pumpAndSettle();

        expect(find.text('Abidjan'), findsOneWidget);
        expect(find.text('Accès en lecture seule'), findsOneWidget);
        expect(find.text('Nouvelle ville'), findsNothing);
        expect(
          find.byKey(const Key('admin-city-edit-city-1')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('admin-city-deactivate-city-1')),
          findsNothing,
        );
      },
    );

    testWidgets('manage scope shows create and row actions', (tester) async {
      await pumpCities(
        tester,
        canManage: true,
        apiService: _FakeTransportService(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nouvelle ville'), findsOneWidget);
      expect(
        find.byKey(const Key('admin-city-edit-city-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('admin-city-deactivate-city-1')),
        findsOneWidget,
      );
    });

    testWidgets('shows loading then empty state', (tester) async {
      await pumpCities(
        tester,
        canManage: true,
        apiService: _FakeTransportService(cities: const []),
      );

      expect(
        find.text('Chargement des villes...'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune ville'), findsOneWidget);
    });

    testWidgets('shows list error with retry', (tester) async {
      await pumpCities(
        tester,
        canManage: true,
        apiService: _FakeTransportService(
          throwOnCityList: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Filtre invalide.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets(
      'sends search, active filter, ordering and pagination',
      (tester) async {
        final service = _FakeTransportService(next: 'next');

        await pumpCities(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          '  abi  ',
        );
        await tester.tap(find.byTooltip('Rechercher'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tous').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Actives').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Par défaut').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pays A-Z').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Page suivante'));
        await tester.pumpAndSettle();

        expect(service.lastQuery, 'abi');
        expect(service.lastIsActive, isTrue);
        expect(service.lastOrdering, 'country');
        expect(service.lastPage, 2);
      },
    );

    testWidgets('opens detail dialog', (tester) async {
      await pumpCities(
        tester,
        canManage: false,
        apiService: _FakeTransportService(),
      );

      await tester.pumpAndSettle();

      final detailFinder = find.byKey(
        const Key('admin-city-detail-city-1'),
      );

      expect(detailFinder, findsOneWidget);

      final detailButton = tester.widget<IconButton>(
        detailFinder,
      );

      expect(detailButton.onPressed, isNotNull);
      detailButton.onPressed!.call();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-city-details-city-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('admin-city-detail-title')),
        findsOneWidget,
      );
    });

    testWidgets(
      'creates city and preserves draft on duplicate error',
      (tester) async {
        final service = _FakeTransportService(
          throwOnCityCreate: true,
        );

        await pumpCities(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Nouvelle ville'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom *'),
          'San Pedro',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Pays *'),
          "Côte d'Ivoire",
        );

        await tester.tap(find.text('Créer'));
        await tester.pumpAndSettle();

        expect(service.cityCreateCalls, 1);
        expect(
          find.text(
            'Une ville existe déjà avec ce nom dans ce pays.',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'San Pedro'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows dependency error on deactivate failure',
      (tester) async {
        final service = _FakeTransportService(
          throwOnCityDeactivate: true,
        );

        await pumpCities(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        final deactivateFinder = find.byKey(
          const Key('admin-city-deactivate-city-1'),
        );

        expect(deactivateFinder, findsOneWidget);

        final deactivateButton = tester.widget<IconButton>(
          deactivateFinder,
        );

        expect(deactivateButton.onPressed, isNotNull);
        deactivateButton.onPressed!.call();

        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('admin-city-deactivate-confirm-dialog'),
          ),
          findsOneWidget,
        );

        final confirmFinder = find.byKey(
          const Key('admin-city-deactivate-confirm'),
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
            'La ville possède encore des dépendances actives.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders at mobile width without mutation overflow',
      (tester) async {
        await pumpCities(
          tester,
          surfaceSize: const Size(320, 700),
          canManage: true,
          apiService: _FakeTransportService(),
        );

        await tester.pumpAndSettle();

        expect(
          find.text("Pays : Côte d'Ivoire"),
          findsOneWidget,
        );
      },
    );
  });
}

Future<void> pumpHome(
  WidgetTester tester, {
  required User user,
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
        body: AdminTransportHomeScreen(
          user: user,
          apiService: apiService,
        ),
      ),
    ),
  );
}

Future<void> pumpCities(
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
        body: AdminCitiesScreen(
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
  final List<AdminCity> cities;
  final bool throwOnCityList;
  final bool throwOnCityCreate;
  final bool throwOnCityDeactivate;
  final String? next;

  int cityCreateCalls = 0;
  String? lastQuery;
  bool? lastIsActive;
  String? lastOrdering;
  int? lastPage;

  _FakeTransportService({
    this.cities = const [_city],
    this.throwOnCityList = false,
    this.throwOnCityCreate = false,
    this.throwOnCityDeactivate = false,
    this.next,
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
    return const PagedResult(
      count: 0,
      next: null,
      previous: null,
      results: [],
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
    if (throwOnCityList) {
      throw ApiException(
        message: 'Filtre invalide.',
        statusCode: 400,
        details: const {
          'code': 'transport_invalid_filter',
          'detail': 'Filtre invalide.',
          'field': 'q',
        },
      );
    }

    lastQuery = query;
    lastIsActive = isActive;
    lastOrdering = ordering;
    lastPage = page;

    return PagedResult(
      count: cities.length,
      next: next,
      previous: page != null && page > 1 ? 'previous' : null,
      results: cities,
    );
  }

  @override
  Future<AdminCity> getCity(String id) async {
    return _city;
  }

  @override
  Future<AdminCity> createCity(
    AdminCityCreateRequest request,
  ) async {
    cityCreateCalls += 1;

    if (throwOnCityCreate) {
      throw ApiException(
        message: 'Une ville existe déjà avec ce nom dans ce pays.',
        statusCode: 400,
        details: const {
          'code': 'transport_duplicate_city',
          'detail': 'Une ville existe déjà avec ce nom dans ce pays.',
          'field': 'name',
        },
      );
    }

    return _city;
  }

  @override
  Future<AdminCity> updateCity(
    String id,
    AdminCityUpdateRequest request,
  ) async {
    return _city;
  }

  @override
  Future<AdminCity> activateCity(String id) async {
    return _city;
  }

  @override
  Future<AdminCity> deactivateCity(String id) async {
    if (throwOnCityDeactivate) {
      throw ApiException(
        message: 'La ville possède encore des dépendances actives.',
        statusCode: 400,
        details: const {
          'code': 'transport_city_has_active_dependencies',
          'detail': 'La ville possède encore des dépendances actives.',
        },
      );
    }

    return _city;
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

const _city = AdminCity(
  id: 'city-1',
  name: 'Abidjan',
  normalizedName: 'abidjan',
  country: "Côte d'Ivoire",
  isActive: true,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T09:00:00Z',
);
