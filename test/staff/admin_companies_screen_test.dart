import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/admin_transport_home_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

void main() {
  group('admin companies screen permissions', () {
    testWidgets('denies access without transport scope', (tester) async {
      await pumpTransportScreen(
        tester,
        user: _user(scopes: const []),
        apiService: _FakeTransportService(),
      );

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
    });

    testWidgets(
      'read scope shows list and hides mutation actions',
      (tester) async {
        await pumpTransportScreen(
          tester,
          user: _user(scopes: const ['admin.transport.read']),
          apiService: _FakeTransportService(),
        );

        await tester.pump();

        expect(find.text('Compagnies'), findsWidgets);
        expect(find.text('CA TRANS'), findsOneWidget);
        expect(find.text('Accès en lecture seule'), findsOneWidget);
        expect(find.text('Nouvelle compagnie'), findsNothing);
        expect(find.byTooltip('Modifier'), findsNothing);
        expect(find.byTooltip('Désactiver'), findsNothing);
      },
    );

    testWidgets('manage scope shows create and row actions', (tester) async {
      await pumpTransportScreen(
        tester,
        user: _user(scopes: const ['admin.transport.manage']),
        apiService: _FakeTransportService(),
      );

      await tester.pump();

      expect(find.text('Nouvelle compagnie'), findsOneWidget);
      expect(find.byTooltip('Modifier'), findsOneWidget);
      expect(find.byTooltip('Désactiver'), findsOneWidget);
    });
  });

  group('admin companies screen states and filters', () {
    testWidgets('shows loading then empty state', (tester) async {
      await pumpTransportScreen(
        tester,
        user: _user(scopes: const ['admin.transport.manage']),
        apiService: _FakeTransportService(companies: const []),
      );

      expect(
        find.text('Chargement des compagnies...'),
        findsOneWidget,
      );

      await tester.pump();

      expect(find.text('Aucune compagnie'), findsOneWidget);
    });

    testWidgets('shows list error with retry', (tester) async {
      await pumpTransportScreen(
        tester,
        user: _user(scopes: const ['admin.transport.manage']),
        apiService: _FakeTransportService(throwOnList: true),
      );

      await tester.pump();

      expect(find.text('Filtre invalide.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('sends search, active filter and ordering', (tester) async {
      final service = _FakeTransportService();

      await pumpTransportScreen(
        tester,
        user: _user(scopes: const ['admin.transport.manage']),
        apiService: service,
      );

      await tester.pump();

      await tester.enterText(
        find.byType(TextField),
        '  ca  ',
      );
      await tester.tap(find.byTooltip('Rechercher'));
      await tester.pump();

      await tester.tap(find.text('Tous').last);
      await tester.pump();

      await tester.tap(find.text('Actives').last);
      await tester.pump();

      await tester.tap(find.text('Par défaut').last);
      await tester.pump();

      await tester.tap(find.text('Création récente').last);
      await tester.pump();

      expect(service.lastQuery, 'ca');
      expect(service.lastIsActive, isTrue);
      expect(service.lastOrdering, '-created_at');
    });

    testWidgets(
      'renders at mobile width without mutation overflow',
      (tester) async {
        await pumpTransportScreen(
          tester,
          surfaceSize: const Size(320, 700),
          user: _user(scopes: const ['admin.transport.manage']),
          apiService: _FakeTransportService(),
        );

        await tester.pump();

        expect(
          find.text(
            'Téléphone service client : +2250101010101',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('admin companies actions', () {
    testWidgets('opens detail dialog in read mode', (tester) async {
      await pumpTransportScreen(
        tester,
        surfaceSize: const Size(1280, 900),
        user: _user(scopes: const ['admin.transport.read']),
        apiService: _FakeTransportService(),
      );

      await tester.pump();

      expect(find.text('CA TRANS'), findsOneWidget);
      expect(find.text('Nouvelle compagnie'), findsNothing);

      expect(
        find.byKey(
          const Key('admin-company-edit-company-1'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const Key('admin-company-deactivate-company-1'),
        ),
        findsNothing,
      );

      final detailButton = find.byKey(
        const Key('admin-company-detail-company-1'),
      );

      expect(detailButton, findsOneWidget);

      await tester.ensureVisible(detailButton);
      await tester.tap(detailButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('admin-company-details-company-1'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const Key('admin-company-detail-title'),
        ),
        findsOneWidget,
      );

      expect(
        find.text('Informations compagnie'),
        findsOneWidget,
      );

      expect(find.text('CAT'), findsWidgets);
      expect(find.text('+2250101010101'), findsWidgets);

      expect(
        find.byKey(
          const Key('admin-company-edit-company-1'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(
          const Key('admin-company-deactivate-company-1'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'submits company creation once through the form',
      (tester) async {
        final service = _FakeTransportService();

        await pumpTransportScreen(
          tester,
          user: _user(scopes: const ['admin.transport.manage']),
          apiService: service,
        );

        await tester.pump();

        await tester.tap(find.text('Nouvelle compagnie'));
        await tester.pump(
          const Duration(milliseconds: 250),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom *'),
          'Nova',
        );

        await tester.tap(find.text('Créer'));
        await tester.pump();

        expect(service.createCalls, 1);
      },
    );

    testWidgets('keeps values after duplicate code error', (tester) async {
      final service = _FakeTransportService(
        throwOnCreate: true,
      );

      await pumpTransportScreen(
        tester,
        user: _user(scopes: const ['admin.transport.manage']),
        apiService: service,
      );

      await tester.pump();

      await tester.tap(find.text('Nouvelle compagnie'));
      await tester.pump(
        const Duration(milliseconds: 250),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom *'),
        'Nova',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Code'),
        'CAT',
      );

      await tester.tap(find.text('Créer'));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 250),
      );

      expect(
        find.text('Une compagnie utilise déjà ce code.'),
        findsOneWidget,
      );

      expect(
        find.widgetWithText(TextFormField, 'Nova'),
        findsOneWidget,
      );

      expect(
        find.widgetWithText(TextFormField, 'CAT'),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows dependency error on deactivate failure',
      (tester) async {
        final service = _FakeTransportService(
          throwOnDeactivate: true,
        );

        await pumpTransportScreen(
          tester,
          surfaceSize: const Size(1280, 900),
          user: _user(
            scopes: const ['admin.transport.manage'],
          ),
          apiService: service,
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Chargement des compagnies...'),
          findsNothing,
        );

        expect(find.text('CA TRANS'), findsOneWidget);

        final deactivateFinder = find.byKey(
          const Key(
            'admin-company-deactivate-company-1',
          ),
        );

        expect(deactivateFinder, findsOneWidget);

        final deactivateButton = tester.widget<IconButton>(
          deactivateFinder,
        );

        expect(
          deactivateButton.onPressed,
          isNotNull,
        );

        // Invoque le vrai callback du bouton sans passer par
        // le hit-test instable de la cellule d'actions de la table.
        deactivateButton.onPressed!.call();

        await tester.pumpAndSettle();

        final confirmDialogFinder = find.byKey(
          const Key(
            'admin-company-deactivate-confirm-dialog',
          ),
        );

        expect(
          confirmDialogFinder,
          findsOneWidget,
        );

        final confirmButtonFinder = find.byKey(
          const Key(
            'admin-company-deactivate-confirm',
          ),
        );

        expect(
          confirmButtonFinder,
          findsOneWidget,
        );

        await tester.tap(confirmButtonFinder);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'La compagnie possède encore '
            'des dépendances actives.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}

Future<void> pumpTransportScreen(
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
  final List<AdminCompany> companies;
  final bool throwOnList;
  final bool throwOnCreate;
  final bool throwOnDeactivate;

  int createCalls = 0;

  String? lastQuery;
  bool? lastIsActive;
  String? lastOrdering;

  _FakeTransportService({
    this.companies = const [_company],
    this.throwOnList = false,
    this.throwOnCreate = false,
    this.throwOnDeactivate = false,
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
    lastIsActive = isActive;
    lastOrdering = ordering;

    return PagedResult(
      count: companies.length,
      next: null,
      previous: null,
      results: companies,
    );
  }

  @override
  Future<AdminCompany> getCompany(String id) async {
    return _company;
  }

  @override
  Future<AdminCompany> createCompany(
    AdminCompanyCreateRequest request,
  ) async {
    createCalls += 1;

    if (throwOnCreate) {
      throw ApiException(
        message: 'Une compagnie utilise déjà ce code.',
        statusCode: 400,
        details: const {
          'code': 'transport_duplicate_company_code',
          'detail': 'Une compagnie utilise déjà ce code.',
          'field': 'code',
        },
      );
    }

    return _company;
  }

  @override
  Future<AdminCompany> updateCompany(
    String id,
    AdminCompanyUpdateRequest request,
  ) async {
    return _company;
  }

  @override
  Future<AdminCompany> activateCompany(String id) async {
    return _company;
  }

  @override
  Future<AdminCompany> deactivateCompany(String id) async {
    if (throwOnDeactivate) {
      throw ApiException(
        message: 'La compagnie possède encore des dépendances actives.',
        statusCode: 400,
        details: const {
          'code': 'transport_company_has_active_dependencies',
          'detail': 'La compagnie possède encore des dépendances actives.',
        },
      );
    }

    return _company;
  }
}

class _FailingTransport implements AdminTransportBaseApiTransport {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    throw StateError(
      'Unexpected real transport GET $path',
    );
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
  }) async {
    throw StateError(
      'Unexpected real transport POST $path',
    );
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
  }) async {
    throw StateError(
      'Unexpected real transport PATCH $path',
    );
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
