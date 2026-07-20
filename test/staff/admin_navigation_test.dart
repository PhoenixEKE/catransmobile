import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/admin/admin_users_home_screen.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';

void main() {
  group('admin staff navigation', () {
    test('admin scopes expose four admin modules', () {
      final user = _internalUser(
        role: InternalRole.admin,
        scopes: const [
          'admin.dashboard.read',
          'admin.users.manage',
          'admin.transport.manage',
          'admin.operations.manage',
        ],
      );

      final ids = StaffMenuItem.forUser(user).map((item) => item.id).toList();

      expect(
          ids,
          containsAllInOrder(const [
            'admin_dashboard',
            'admin_users',
            'admin_transport',
            'admin_operations',
          ]));
      expect(ids.where((id) => id.startsWith('admin_')).length, 4);
    });

    test('director read scopes expose admin modules without role fallback', () {
      final user = _internalUser(
        role: InternalRole.director,
        scopes: const [
          'admin.dashboard.read',
          'admin.users.read',
          'admin.transport.read',
          'admin.operations.read',
        ],
      );

      final ids = StaffMenuItem.forUser(user).map((item) => item.id).toList();

      expect(ids, const [
        'admin_dashboard',
        'admin_users',
        'admin_transport',
        'admin_operations',
      ]);
    });

    test('cashier and station manager do not get admin modules', () {
      for (final role in [InternalRole.cashier, InternalRole.station_manager]) {
        final user = _internalUser(
          role: role,
          scopes: const ['station.reservations.search'],
        );
        final ids = StaffMenuItem.forUser(user).map((item) => item.id).toList();
        expect(ids.any((id) => id.startsWith('admin_')), isFalse);
      }
    });

    test('explicit station scope is not completed by admin role', () {
      final user = _internalUser(
        role: InternalRole.admin,
        scopes: const ['boarding.validate'],
      );

      expect(
        StaffMenuItem.forUser(user).map((item) => item.id).toList(),
        const ['boarding'],
      );
    });

    testWidgets('read only banner is shown on admin user entry',
        (tester) async {
      final user = _internalUser(
        role: InternalRole.director,
        scopes: const ['admin.users.read'],
      );

      await tester
          .pumpWidget(MaterialApp(home: AdminUsersHomeScreen(user: user)));

      expect(find.text('Accès en lecture seule'), findsOneWidget);
      expect(find.text('Utilisateurs internes'), findsOneWidget);
    });
  });
}

User _internalUser({
  required InternalRole role,
  required List<String> scopes,
}) {
  return User(
    id: 'user-${role.name}',
    lastname: 'Test',
    firstname: 'Staff',
    phoneNumber: '+2250101010101',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: InternalProfile(
      id: 'profile-${role.name}',
      role: role,
      roleLabel: role.name,
    ),
    scopes: scopes,
  );
}
