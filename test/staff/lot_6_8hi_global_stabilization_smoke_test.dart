import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';
import 'package:catrans_app/services/auth_service.dart';

import '../support/fake_auth.dart';

void main() {
  group('LOT 6.8HI global stabilization smoke', () {
    test('support/accounting/marketing roles expose only routed menu entries',
        () {
      final support = StaffMenuItem.forUser(
        _roleUser(role: InternalRole.support, scopes: const []),
      );
      final accounting = StaffMenuItem.forUser(
        _roleUser(role: InternalRole.accounting, scopes: const []),
      );
      final marketing = StaffMenuItem.forUser(
        _roleUser(role: InternalRole.marketing, scopes: const []),
      );

      expect(support.map((item) => item.id).toList(), ['home']);
      expect(accounting.map((item) => item.id).toList(), ['home']);
      expect(marketing.map((item) => item.id).toList(), ['home']);

      expect(
        resolveInitialStaffMenuId(
          menuItems: support,
          scopes: const <String>{},
          role: InternalRole.support,
        ),
        'home',
      );
    });

    test('admin and director menus no longer include unrouted ids', () {
      final admin = StaffMenuItem.forUser(
        _roleUser(
          role: InternalRole.admin,
          scopes: const ['admin.dashboard.read', 'finance.read'],
        ),
      );
      final director = StaffMenuItem.forUser(
        _roleUser(
          role: InternalRole.director,
          scopes: const ['admin.dashboard.read', 'finance.read'],
        ),
      );

      final blockedIds = [
        'finance',
        'support_reservations',
        'support_payments',
        'support_tickets',
        'payments',
        'financial_reports',
        'marketing_pending',
      ];

      for (final id in blockedIds) {
        expect(admin.any((item) => item.id == id), isFalse);
        expect(director.any((item) => item.id == id), isFalse);
      }
    });

    testWidgets('support drawer no longer shows unrouted support placeholders',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _wrapShell(_roleUser(
        role: InternalRole.support,
        scopes: const ['support.reservations.read', 'support.payments.read'],
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Recherche réservation'), findsNothing);
      expect(find.text('Recherche paiement'), findsNothing);
      expect(find.text('Recherche ticket'), findsNothing);
    });
  });
}

Future<Widget> _wrapShell(User user) async {
  final authService = AuthService(
    authApiService: FakeAuthApiService()..userOnMe = user,
    tokenStorage: FakeTokenStorage()..seedAccessToken('token'),
  );
  await authService.loadUser();
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: const MaterialApp(home: StaffShellScreen()),
  );
}

User _roleUser({
  required InternalRole role,
  required List<String> scopes,
}) {
  return User(
    id: 'user-${role.name}',
    lastname: 'Test',
    firstname: 'User',
    phoneNumber: '+2250100000000',
    email: '${role.name}@catrans.ci',
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
