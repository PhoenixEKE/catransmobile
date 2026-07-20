import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/admin/transport/service_classes/admin_service_classes_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin service classes screen', () {
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

        final classesNavigation = find.text('Classes');
        expect(classesNavigation, findsOneWidget);

        await tester.tap(classesNavigation);
        await tester.pumpAndSettle();

        expect(find.text('Économie'), findsOneWidget);
        expect(find.text('Accès en lecture seule'), findsOneWidget);
        expect(find.text('Nouvelle classe'), findsNothing);
        expect(
          find.byKey(
            const Key('admin-service-class-edit-class-1'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const Key('admin-service-class-deactivate-class-1'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('manage scope shows create and row actions', (tester) async {
      await pumpServiceClasses(
        tester,
        canManage: true,
        apiService: _FakeTransportService(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nouvelle classe'), findsOneWidget);
      expect(
        find.byKey(
          const Key('admin-service-class-edit-class-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('admin-service-class-deactivate-class-1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows loading then empty state', (tester) async {
      await pumpServiceClasses(
        tester,
        canManage: true,
        apiService: _FakeTransportService(
          serviceClasses: const [],
        ),
      );

      expect(
        find.text('Chargement des classes...'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Aucune classe de service'),
        findsOneWidget,
      );
    });

    testWidgets('shows list error', (tester) async {
      await pumpServiceClasses(
        tester,
        canManage: true,
        apiService: _FakeTransportService(
          throwOnList: true,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Filtre invalide.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets(
      'sends search filters ordering and pagination',
      (tester) async {
        final service = _FakeTransportService(next: 'next');

        await pumpServiceClasses(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          '  eco  ',
        );
        await tester.tap(find.byTooltip('Rechercher'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tous').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Actives').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Toutes').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Autorisée').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Par défaut').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Code A-Z').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Page suivante'));
        await tester.pumpAndSettle();

        expect(service.lastQuery, 'eco');
        expect(service.lastIsActive, isTrue);
        expect(service.lastAllowsSeatSelection, isTrue);
        expect(service.lastOrdering, 'code');
        expect(service.lastPage, 2);
      },
    );

    testWidgets('opens detail dialog', (tester) async {
      await pumpServiceClasses(
        tester,
        canManage: false,
        apiService: _FakeTransportService(),
      );

      await tester.pumpAndSettle();

      final detailFinder = find.byKey(
        const Key('admin-service-class-detail-class-1'),
      );

      expect(detailFinder, findsOneWidget);

      final detailButton = tester.widget<IconButton>(
        detailFinder,
      );

      expect(detailButton.onPressed, isNotNull);
      detailButton.onPressed!.call();

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('admin-service-class-details-class-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('admin-service-class-detail-title'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'creates class and preserves draft on code error',
      (tester) async {
        final service = _FakeTransportService(
          throwOnCreate: true,
        );

        await pumpServiceClasses(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Nouvelle classe'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Code *'),
          'ECONOMIE',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom *'),
          'Économie',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Points par ticket',
          ),
          '5',
        );

        await tester.tap(find.text('Créer'));
        await tester.pumpAndSettle();

        expect(service.createCalls, 1);
        expect(
          find.text(
            'Une classe de service utilise déjà ce code.',
          ),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'ECONOMIE'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows locked code error on edit', (tester) async {
      final service = _FakeTransportService(
        throwOnUpdate: true,
      );

      await pumpServiceClasses(
        tester,
        canManage: true,
        apiService: service,
      );

      await tester.pumpAndSettle();

      final editFinder = find.byKey(
        const Key('admin-service-class-edit-class-1'),
      );

      expect(editFinder, findsOneWidget);

      final editButton = tester.widget<IconButton>(
        editFinder,
      );

      expect(editButton.onPressed, isNotNull);
      editButton.onPressed!.call();

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Code *'),
        'PRESTIGE',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Le code de cette classe ne peut plus être modifié '
          'car elle est déjà utilisée.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows dependency error on deactivate failure',
      (tester) async {
        final service = _FakeTransportService(
          throwOnDeactivate: true,
        );

        await pumpServiceClasses(
          tester,
          canManage: true,
          apiService: service,
        );

        await tester.pumpAndSettle();

        final deactivateFinder = find.byKey(
          const Key(
            'admin-service-class-deactivate-class-1',
          ),
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
            const Key(
              'admin-service-class-deactivate-confirm-dialog',
            ),
          ),
          findsOneWidget,
        );

        final confirmFinder = find.byKey(
          const Key(
            'admin-service-class-deactivate-confirm',
          ),
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
            'La classe de service possède encore '
            'des dépendances actives.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders at mobile width without mutation overflow',
      (tester) async {
        await pumpServiceClasses(
          tester,
          surfaceSize: const Size(320, 700),
          canManage: true,
          apiService: _FakeTransportService(),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Sélection siège : automatique'),
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
        body: AdminTransportHomeScreen(
          user: user,
          apiService: apiService,
        ),
      ),
    ),
  );
}

Future<void> pumpServiceClasses(
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
        body: AdminServiceClassesScreen(
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
  final List<AdminServiceClass> serviceClasses;
  final bool throwOnList;
  final bool throwOnCreate;
  final bool throwOnUpdate;
  final bool throwOnDeactivate;
  final String? next;

  int createCalls = 0;
  String? lastQuery;
  bool? lastIsActive;
  bool? lastAllowsSeatSelection;
  String? lastOrdering;
  int? lastPage;

  _FakeTransportService({
    this.serviceClasses = const [_serviceClass],
    this.throwOnList = false,
    this.throwOnCreate = false,
    this.throwOnUpdate = false,
    this.throwOnDeactivate = false,
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
  Future<PagedResult<AdminServiceClass>> listServiceClasses({
    String? query,
    bool? allowsSeatSelection,
    bool? isActive,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    if (throwOnList) {
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
    lastAllowsSeatSelection = allowsSeatSelection;
    lastIsActive = isActive;
    lastOrdering = ordering;
    lastPage = page;

    return PagedResult(
      count: serviceClasses.length,
      next: next,
      previous: page != null && page > 1 ? 'previous' : null,
      results: serviceClasses,
    );
  }

  @override
  Future<AdminServiceClass> getServiceClass(
    String id,
  ) async {
    return _serviceClass;
  }

  @override
  Future<AdminServiceClass> createServiceClass(
    AdminServiceClassCreateRequest request,
  ) async {
    createCalls += 1;

    if (throwOnCreate) {
      throw ApiException(
        message: 'Une classe de service utilise déjà ce code.',
        statusCode: 400,
        details: const {
          'code': 'transport_duplicate_service_class_code',
          'detail': 'Une classe de service utilise déjà ce code.',
          'field': 'code',
        },
      );
    }

    return _serviceClass;
  }

  @override
  Future<AdminServiceClass> updateServiceClass(
    String id,
    AdminServiceClassUpdateRequest request,
  ) async {
    if (throwOnUpdate) {
      throw ApiException(
        message: 'Le code de cette classe ne peut plus être modifié '
            'car elle est déjà utilisée.',
        statusCode: 400,
        details: const {
          'code': 'transport_service_class_code_locked',
          'detail': 'Le code de cette classe ne peut plus être modifié '
              'car elle est déjà utilisée.',
          'field': 'code',
        },
      );
    }

    return _serviceClass;
  }

  @override
  Future<AdminServiceClass> activateServiceClass(
    String id,
  ) async {
    return _serviceClass;
  }

  @override
  Future<AdminServiceClass> deactivateServiceClass(
    String id,
  ) async {
    if (throwOnDeactivate) {
      throw ApiException(
        message: 'La classe de service possède encore '
            'des dépendances actives.',
        statusCode: 400,
        details: const {
          'code': 'transport_service_class_has_active_dependencies',
          'detail': 'La classe de service possède encore '
              'des dépendances actives.',
        },
      );
    }

    return _serviceClass;
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

const _serviceClass = AdminServiceClass(
  id: 'class-1',
  code: 'ECONOMIE',
  name: 'Économie',
  defaultLoyaltyPoints: 5,
  rewardThresholdPoints: 50,
  allowsSeatSelection: false,
  isActive: true,
  createdAt: '2026-07-20T08:00:00Z',
  updatedAt: '2026-07-20T09:00:00Z',
);
