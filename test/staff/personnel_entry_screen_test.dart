import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/auth/personnel_entry_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/screens/staff/pages/staff_profile_incomplete_page.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';
import 'package:catrans_app/services/auth_service.dart';

import '../support/fake_auth.dart';

// No real network is used anywhere in this file: `FakeAuthApiService` and
// `FakeTokenStorage` (test/support/fake_auth.dart) stand in for the real
// `AuthApiService`/`TokenStorage` and never touch `ApiClient`/Dio. Nothing
// here weakens `AppConfig`/`API_BASE_URL` validation — that path is never
// reached because the fakes override every network method directly.

void main() {
  group('/personnel entry screen', () {
    testWidgets('shows the personnel email/password login form when no user is logged in',
        (tester) async {
      final authService = AuthService(
        authApiService: FakeAuthApiService(),
        tokenStorage: FakeTokenStorage(),
      );

      await tester.pumpWidget(_wrap(authService));
      await tester.pumpAndSettle();

      expect(find.text('Espace personnel CA TRANS'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email professionnel'),
          findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
    });

    testWidgets('never shows a phone number field on /personnel',
        (tester) async {
      final authService = AuthService(
        authApiService: FakeAuthApiService(),
        tokenStorage: FakeTokenStorage(),
      );

      await tester.pumpWidget(_wrap(authService));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.textContaining('téléphone'), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
      // No traveller registration link on the personnel entry point either.
      expect(find.text('CRÉER UN COMPTE'), findsNothing);
    });

    testWidgets('an already logged-in staff user is redirected to their portal',
        (tester) async {
      final storage = FakeTokenStorage()..seedAccessToken('staff-token');
      // `support` (like admin/director/accounting/marketing) resolves its
      // initial menu selection to 'home' -> StaffHomePage, which is built
      // synchronously from user/menuItems with no network call. Cashier or
      // station_manager would instead land on a data-fetching module
      // screen, which this network-free widget test intentionally avoids.
      final api = FakeAuthApiService()
        ..userOnMe = _staffUser(role: InternalRole.support, scopes: const []);
      final authService = AuthService(authApiService: api, tokenStorage: storage);

      await tester.pumpWidget(_wrap(authService));
      await tester.pumpAndSettle();

      // Redirected away from the login form into AuthRedirectService's
      // staff branch (StaffShellScreen).
      expect(find.byType(StaffShellScreen), findsOneWidget);
      expect(find.text('Espace personnel CA TRANS'), findsNothing);
    });

    testWidgets('an already logged-in customer is cleanly refused, not silently redirected',
        (tester) async {
      final storage = FakeTokenStorage()..seedAccessToken('customer-token');
      final api = FakeAuthApiService()..userOnMe = _customerUser();
      final authService = AuthService(authApiService: api, tokenStorage: storage);

      await tester.pumpWidget(_wrap(authService));
      await tester.pumpAndSettle();

      expect(find.text('Espace réservé au personnel'), findsOneWidget);
      expect(find.text('Retour à l\'application voyageur'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(find.text('Espace personnel CA TRANS'), findsNothing);
    });

    testWidgets('a staff user with an incomplete internal profile is redirected correctly',
        (tester) async {
      final storage = FakeTokenStorage()..seedAccessToken('incomplete-token');
      final api = FakeAuthApiService()..userOnMe = _staffUserWithoutProfile();
      final authService = AuthService(authApiService: api, tokenStorage: storage);

      await tester.pumpWidget(_wrap(authService));
      await tester.pumpAndSettle();

      expect(find.byType(StaffProfileIncompletePage), findsOneWidget);
      expect(find.byType(StaffAccessDeniedPage), findsNothing);
    });
  });
}

Widget _wrap(AuthService authService) {
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: const MaterialApp(home: PersonnelEntryScreen()),
  );
}

User _staffUser({
  required InternalRole role,
  List<String> scopes = const [],
}) {
  return User(
    id: 'staff-1',
    lastname: 'Ouattara',
    firstname: 'Jean',
    phoneNumber: '+2250101010101',
    email: 'jean.ouattara@catrans.ci',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: InternalProfile(
      id: 'profile-1',
      role: role,
      roleLabel: role.name,
    ),
    scopes: scopes,
  );
}

User _staffUserWithoutProfile() {
  return User(
    id: 'staff-2',
    lastname: 'Kone',
    firstname: 'Awa',
    phoneNumber: '+2250101010102',
    email: 'awa.kone@catrans.ci',
    userType: UserType.staff,
    isStaff: true,
    scopes: const [],
  );
}

User _customerUser() {
  return User(
    id: 'customer-1',
    lastname: 'Client',
    firstname: 'Voyageur',
    phoneNumber: '+2250101010103',
    userType: UserType.customer,
    scopes: const [],
  );
}
