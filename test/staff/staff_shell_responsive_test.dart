import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/widgets/staff/staff_sidebar.dart';

import '../support/fake_auth.dart';

// Uses a `support`-role fixture with no scopes so the shell's initial
// selection resolves to 'home' -> StaffHomePage, which builds synchronously
// with no network call (see personnel_entry_screen_test.dart for the same
// rationale). No real network is used anywhere in this file.

void main() {
  group('StaffShellScreen responsive shell', () {
    testWidgets('shows a permanent sidebar and no drawer/menu button at desktop width',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _wrap(_supportUser()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffSidebar), findsOneWidget);
      expect(find.byTooltip('Menu'), findsNothing);
    });

    testWidgets('shows a drawer reachable via the menu button under 900px width',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _wrap(_supportUser()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Menu'), findsOneWidget);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.byType(StaffSidebar), findsOneWidget);
    });

    testWidgets('renders at 320x700 with no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _wrap(_supportUser()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // A closed DrawerController does not build its child at all
      // (see framework's DrawerControllerState._buildDrawer, dismissed
      // branch), so this also confirms no permanent sidebar is mounted.
      expect(find.byType(StaffSidebar), findsNothing);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('closes the drawer and keeps the selected item after picking a menu entry',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(await _wrap(_supportUser()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      // Support role's second menu entry: "Recherche réservation". Scoped
      // to the drawer since the same label may also appear in the
      // StaffHomePage quick-actions list underneath.
      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Recherche réservation'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Drawer), findsNothing);
      expect(find.text('Recherche réservation'), findsWidgets);
    });
  });
}

Future<Widget> _wrap(User user) async {
  final authService = AuthService(
    authApiService: FakeAuthApiService()..userOnMe = user,
    tokenStorage: FakeTokenStorage()..seedAccessToken('token'),
  );
  // StaffShellScreen reads `authService.currentUser` synchronously (it
  // assumes the caller — normally PersonnelEntryScreen/AuthRedirectService —
  // already resolved the session), so the fake user must be loaded first.
  await authService.loadUser();
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: const MaterialApp(home: StaffShellScreen()),
  );
}

User _supportUser() {
  return User(
    id: 'support-1',
    lastname: 'Traore',
    firstname: 'Fatou',
    phoneNumber: '+2250101010104',
    email: 'fatou.traore@catrans.ci',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: const InternalProfile(
      id: 'profile-support',
      role: InternalRole.support,
      roleLabel: 'Support',
    ),
    scopes: const [],
  );
}
