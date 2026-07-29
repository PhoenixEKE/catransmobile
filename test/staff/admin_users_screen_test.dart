import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/screens/staff/admin/admin_users_home_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';

void main() {
  group('admin users screen permissions', () {
    testWidgets('denies access without read or manage scope', (tester) async {
      await pumpAdminUsersScreen(
        tester,
        child: AdminUsersHomeScreen(user: _user(scopes: const [])),
      );

      expect(find.byType(StaffAccessDeniedPage), findsOneWidget);
    });

    testWidgets('read scope shows module without create action',
        (tester) async {
      await pumpAdminUsersScreen(
        tester,
        child: AdminUsersHomeScreen(
          user: _user(scopes: const ['admin.users.read']),
          apiService: _FakeAdminUsersApiService(),
        ),
      );
      await tester.pump();

      expect(find.text('Utilisateurs internes'), findsOneWidget);
      expect(find.text('Accès en lecture seule'), findsOneWidget);
      expect(find.text('Ajouter un utilisateur'), findsNothing);
    });

    testWidgets('manage scope shows create action and list', (tester) async {
      await pumpAdminUsersScreen(
        tester,
        child: AdminUsersHomeScreen(
          user: _user(scopes: const ['admin.users.manage']),
          apiService: _FakeAdminUsersApiService(),
        ),
      );
      await tester.pump();

      expect(find.text('Ajouter un utilisateur'), findsOneWidget);
      expect(find.text('Aya Koffi'), findsOneWidget);
      expect(find.text('cashier@catrans.test'), findsOneWidget);
    });
  });

  group('staff loading state', () {
    testWidgets('fits a mobile width with a long message', (tester) async {
      await pumpAdminUsersScreen(
        tester,
        surfaceSize: const Size(320, 640),
        child: const StaffLoadingState(
          message:
              'Chargement des utilisateurs internes et des guichets disponibles...',
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffLoadingState), findsOneWidget);
      expect(find.textContaining('Chargement des utilisateurs internes'),
          findsOneWidget);
    });
  });
}

Future<void> pumpAdminUsersScreen(
  WidgetTester tester, {
  required Widget child,
  Size surfaceSize = const Size(1280, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

User _user({required List<String> scopes}) {
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

class _FakeAdminUsersApiService extends AdminUsersApiService {
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
    return const PagedResult(
      count: 1,
      next: null,
      previous: null,
      results: [
        AdminInternalUserSummary(
          id: 'user-1',
          email: 'cashier@catrans.test',
          phoneNumber: '+2250101010101',
          lastname: 'Koffi',
          firstname: 'Aya',
          isActive: true,
          role: 'cashier',
          roleLabel: 'Guichetier',
          station: StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon'),
          counter: StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1'),
        ),
      ],
    );
  }

  @override
  Future<List<AdminInternalRoleOption>> listRoles() async {
    return const [
      AdminInternalRoleOption(
        value: 'cashier',
        label: 'Guichetier',
        requiresStation: true,
        requiresCounter: true,
        allowsStation: true,
        allowsCounter: true,
      ),
    ];
  }

  @override
  Future<List<StaffStationRef>> listStations() async {
    return const [StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon')];
  }

  @override
  Future<List<StaffCounterRef>> listCounters(
      {required String stationId}) async {
    return const [StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1')];
  }

  @override
  Future<AdminInternalUserDetail> getUser(String id) async {
    return const AdminInternalUserDetail(
      id: 'user-1',
      email: 'cashier@catrans.test',
      phoneNumber: '+2250101010101',
      lastname: 'Koffi',
      firstname: 'Aya',
      isActive: true,
      role: 'cashier',
      roleLabel: 'Guichetier',
    );
  }
}
