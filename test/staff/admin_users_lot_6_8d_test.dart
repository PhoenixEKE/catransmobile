import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/screens/staff/admin/admin_users_home_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';

void main() {
  group('LOT 6.8D admin users module', () {
    testWidgets('1. chargement initial réussi', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(api.listUsersCalls, 1);
      expect(api.listRolesCalls, 1);
      expect(api.listStationsCalls, 1);
      expect(find.text('Utilisateurs internes'), findsOneWidget);
    });

    testWidgets('2. liste réelle affichée', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(find.text('Aya Koffi'), findsOneWidget);
      expect(find.text('cashier@catrans.test'), findsOneWidget);
    });

    testWidgets('3. recherche recharge les données', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await tester.enterText(
        find.byKey(const Key('admin-users-search-field')),
        'Aya',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(api.listUsersCalls, greaterThanOrEqualTo(2));
      expect(api.lastQuery, 'Aya');
      expect(api.lastPage, 1);
    });

    testWidgets('4. filtre rôle recharge la page 1', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await tester.tap(find.byKey(const Key('admin-users-role-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guichetier').last);
      await tester.pumpAndSettle();

      expect(api.lastRole, 'cashier');
      expect(api.lastPage, 1);
    });

    testWidgets('5. pagination suivante', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(tester, find.byTooltip('Page suivante'));
      await tester.pumpAndSettle();

      expect(api.lastPage, 2);
    });

    testWidgets('6. pagination précédente', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(tester, find.byTooltip('Page suivante'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.byTooltip('Page précédente'));
      await tester.pumpAndSettle();

      expect(api.lastPage, 1);
    });

    testWidgets('7. état vide', (tester) async {
      final api = _FakeAdminUsersApiService(
        listUsersPlans: [
          const PagedResult<AdminInternalUserSummary>(
            count: 0,
            next: null,
            previous: null,
            results: [],
          ),
          const PagedResult<AdminInternalUserSummary>(
            count: 0,
            next: null,
            previous: null,
            results: [],
          ),
        ],
      );
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(find.byKey(const Key('admin-users-empty-state')), findsOneWidget);
    });

    testWidgets('8. erreur globale + retry', (tester) async {
      final api = _FakeAdminUsersApiService(
        listUsersPlans: [
          ApiException(message: 'Erreur liste'),
          _pageOne,
        ],
      );
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(find.byKey(const Key('admin-users-error-state')), findsOneWidget);
      expect(find.textContaining('Erreur liste'), findsOneWidget);

      await _tapVisible(tester, find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(api.listUsersCalls, 2);
      expect(find.byKey(const Key('admin-users-error-state')), findsNothing);
      expect(find.text('Aya Koffi'), findsOneWidget);
    });

    testWidgets('9. sans scope lecture: accès refusé et zéro appel API',
        (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(
        tester,
        apiService: api,
        user: _userWithScopes(const []),
      );

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
      expect(api.listUsersCalls, 0);
      expect(api.listRolesCalls, 0);
      expect(api.listStationsCalls, 0);
    });

    testWidgets('10. bouton création masqué sans scope manage', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(
        tester,
        apiService: api,
        user: _readOnlyUser(),
      );

      expect(find.byKey(const Key('admin-users-create-button')), findsNothing);
    });

    testWidgets('11. formulaire création valide', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-create-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('admin-user-form-firstname')), 'Awa');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-lastname')), 'Bamba');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-email')), 'awa@catrans.test');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-phone')), '+2250701002003');

      await _tapVisible(tester, find.byKey(const Key('admin-user-form-role')));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Guichetier').last);
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-user-form-station')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('YOP - Yopougon').last);
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-user-form-counter')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('G1 - Guichet 1').last);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('admin-user-form-password')), 'Admin@1234');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-password-confirm')),
          'Admin@1234');

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-user-form-submit')),
      );
      await tester.pumpAndSettle();

      expect(api.createCalls, 1);
      expect(api.lastCreateRequest?.role, 'cashier');
      expect(api.lastCreateRequest?.stationId, 'station-1');
      expect(api.lastCreateRequest?.counterId, 'counter-1');
    });

    testWidgets('12. erreurs création affichées', (tester) async {
      final api = _FakeAdminUsersApiService(
        createPlans: [
          ApiException(
            message: 'Validation',
            statusCode: 400,
            details: {
              'email': ['Adresse email déjà utilisée.']
            },
          ),
        ],
      );
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-create-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('admin-user-form-firstname')), 'Awa');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-lastname')), 'Bamba');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-email')), 'awa@catrans.test');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-phone')), '+2250701002003');
      await _tapVisible(tester, find.byKey(const Key('admin-user-form-role')));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Direction').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('admin-user-form-password')), 'Admin@1234');
      await tester.enterText(
          find.byKey(const Key('admin-user-form-password-confirm')),
          'Admin@1234');

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-user-form-submit')),
      );
      await tester.pumpAndSettle();

      expect(api.createCalls, 1);
      expect(find.text('Adresse email déjà utilisée.'), findsOneWidget);
    });

    testWidgets('13. formulaire modification prérempli', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-actions-user-1')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Modifier').last);
      await tester.pumpAndSettle();

      expect(find.text('Modifier l’utilisateur'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Aya'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Koffi'), findsOneWidget);
    });

    testWidgets('14. aucun mot de passe prérempli', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-actions-user-1')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Modifier').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin-user-form-password')), findsNothing);
      expect(find.byKey(const Key('admin-user-form-password-confirm')),
          findsNothing);
    });

    testWidgets('15. activation/désactivation avec confirmation',
        (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-actions-user-1')),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Désactiver').last);
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Désactiver').last);
      await tester.pumpAndSettle();

      expect(api.deactivateCalls, 1);
    });

    testWidgets('16. action masquée sans scope manage', (tester) async {
      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _readOnlyUser());

      await _tapVisible(
        tester,
        find.byKey(const Key('admin-users-actions-user-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consulter'), findsOneWidget);
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Désactiver'), findsNothing);
      expect(find.text('Activer'), findsNothing);
    });

    testWidgets('17. desktop sans overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-users-table-view')), findsOneWidget);
    });

    testWidgets('18. tablette sans overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-users-table-view')), findsOneWidget);
    });

    testWidgets('19. mobile 320x700 sans overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('admin-users-cards-view')), findsOneWidget);
    });

    testWidgets('20. actions non superposées sur mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _FakeAdminUsersApiService();
      await _pumpScreen(tester, apiService: api, user: _managerUser());

      expect(
        find.byKey(const Key('admin-users-actions-user-1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeAdminUsersApiService apiService,
  required User user,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminUsersHomeScreen(
          user: user,
          apiService: apiService,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

User _managerUser() {
  return _userWithScopes(const ['admin.users.manage']);
}

User _readOnlyUser() {
  return _userWithScopes(const ['admin.users.read']);
}

User _userWithScopes(List<String> scopes) {
  return User(
    id: 'staff-admin-1',
    lastname: 'Admin',
    firstname: 'User',
    phoneNumber: '+2250700000000',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: const InternalProfile(
      id: 'profile-admin-1',
      role: InternalRole.admin,
      roleLabel: 'Administrateur',
    ),
    scopes: scopes,
  );
}

class _FakeAdminUsersApiService extends AdminUsersApiService {
  final List<Object> listUsersPlans;
  final List<Object> createPlans;

  int listUsersCalls = 0;
  int listRolesCalls = 0;
  int listStationsCalls = 0;
  int listCountersCalls = 0;
  int getUserCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;

  String? lastQuery;
  String? lastRole;
  String? lastStationId;
  String? lastCounterId;
  bool? lastIsActive;
  int lastPage = 1;
  int lastPageSize = 20;

  AdminInternalUserCreateRequest? lastCreateRequest;

  _FakeAdminUsersApiService({
    this.listUsersPlans = const [],
    this.createPlans = const [],
  }) : super(apiClient: _buildTestApiClient());

  @override
  Future<PagedResult<AdminInternalUserSummary>> listUsers({
    String? query,
    String? role,
    String? stationId,
    String? counterId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    listUsersCalls += 1;
    lastQuery = query;
    lastRole = role;
    lastStationId = stationId;
    lastCounterId = counterId;
    lastIsActive = isActive;
    lastPage = page;
    lastPageSize = pageSize;

    final plan = _resolve(listUsersPlans, listUsersCalls, _pageFor(page));
    if (plan is Exception) throw plan;
    return plan as PagedResult<AdminInternalUserSummary>;
  }

  @override
  Future<List<AdminInternalRoleOption>> listRoles() async {
    listRolesCalls += 1;
    return const [
      AdminInternalRoleOption(
        value: 'cashier',
        label: 'Guichetier',
        requiresStation: true,
        requiresCounter: true,
        allowsStation: true,
        allowsCounter: true,
      ),
      AdminInternalRoleOption(
        value: 'director',
        label: 'Direction',
        requiresStation: false,
        requiresCounter: false,
        allowsStation: false,
        allowsCounter: false,
      ),
    ];
  }

  @override
  Future<List<StaffStationRef>> listStations() async {
    listStationsCalls += 1;
    return const [
      StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon'),
      StaffRef(id: 'station-2', code: 'ABO', name: 'Abobo'),
    ];
  }

  @override
  Future<List<StaffCounterRef>> listCounters(
      {required String stationId}) async {
    listCountersCalls += 1;
    if (stationId == 'station-1') {
      return const [
        StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1'),
      ];
    }
    return const [
      StaffRef(id: 'counter-2', code: 'G2', name: 'Guichet 2'),
    ];
  }

  @override
  Future<AdminInternalUserDetail> getUser(String id) async {
    getUserCalls += 1;
    return _detailUser1;
  }

  @override
  Future<AdminInternalUserDetail> createUser(
      AdminInternalUserCreateRequest request) async {
    createCalls += 1;
    lastCreateRequest = request;
    final plan = _resolve(createPlans, createCalls, _detailUser1);
    if (plan is Exception) throw plan;
    return plan as AdminInternalUserDetail;
  }

  @override
  Future<AdminInternalUserDetail> updateUser(
    String id,
    AdminInternalUserUpdateRequest request,
  ) async {
    updateCalls += 1;
    return _detailUser1;
  }

  @override
  Future<AdminInternalUserDetail> activateUser(String id) async {
    activateCalls += 1;
    return _detailUser1;
  }

  @override
  Future<AdminInternalUserDetail> deactivateUser(String id) async {
    deactivateCalls += 1;
    return _detailUser1;
  }

  PagedResult<AdminInternalUserSummary> _pageFor(int page) {
    if (page <= 1) {
      return _pageOne;
    }
    if (page == 2) {
      return const PagedResult(
        count: 2,
        next: null,
        previous: '/api/v1/admin/users/internal/?page=1',
        results: [_user2],
      );
    }
    return const PagedResult(
      count: 2,
      next: null,
      previous: '/api/v1/admin/users/internal/?page=2',
      results: [],
    );
  }
}

Object _resolve(List<Object> plans, int callNumber, Object fallback) {
  final index = callNumber - 1;
  if (index < plans.length) return plans[index];
  return fallback;
}

const _user1 = AdminInternalUserSummary(
  id: 'user-1',
  email: 'cashier@catrans.test',
  phoneNumber: '+2250701002001',
  lastname: 'Koffi',
  firstname: 'Aya',
  isActive: true,
  role: 'cashier',
  roleLabel: 'Guichetier',
  station: StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon'),
  counter: StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1'),
);

const _user2 = AdminInternalUserSummary(
  id: 'user-2',
  email: 'manager@catrans.test',
  phoneNumber: '+2250701002002',
  lastname: 'Yao',
  firstname: 'Serge',
  isActive: false,
  role: 'station_manager',
  roleLabel: 'Responsable de gare',
  station: StaffRef(id: 'station-2', code: 'ABO', name: 'Abobo'),
);

const _detailUser1 = AdminInternalUserDetail(
  id: 'user-1',
  email: 'cashier@catrans.test',
  phoneNumber: '+2250701002001',
  lastname: 'Koffi',
  firstname: 'Aya',
  isActive: true,
  role: 'cashier',
  roleLabel: 'Guichetier',
  station: StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon'),
  counter: StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1'),
);

const _pageOne = PagedResult(
  count: 2,
  next: '/api/v1/admin/users/internal/?page=2',
  previous: null,
  results: [_user1],
);

ApiClient _buildTestApiClient() {
  return ApiClient(
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://test.invalid/api/v1/',
      ),
    ),
  );
}
