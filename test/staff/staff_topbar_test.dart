import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/widgets/staff/staff_topbar.dart';

void main() {
  group('StaffTopbar responsive P0 fix', () {
    testWidgets('a long real name at 320px width causes no RenderFlex overflow',
        (tester) async {
      final user = User(
        id: 'u1',
        lastname: 'Ouattara',
        firstname: 'Jean-Baptiste',
        phoneNumber: '+2250101010101',
        email: 'jean-baptiste.ouattara@catrans.ci',
        userType: UserType.staff,
        isStaff: true,
        internalProfile: const InternalProfile(
          id: 'p1',
          role: InternalRole.station_manager,
          roleLabel: 'Responsable de gare',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StaffTopbar(
                user: user,
                title: 'Tableau de bord gare',
                onLogout: () {},
                onOpenMenu: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Title/subtitle never disappear, even when the identity block hides.
      expect(find.text('Tableau de bord gare'), findsOneWidget);
      // Avatar (initials) and logout stay reachable.
      expect(find.text('JO'), findsOneWidget);
      expect(find.byTooltip('Déconnexion'), findsOneWidget);
      expect(find.byTooltip('Menu'), findsOneWidget);
    });

    testWidgets('shows the name/role block once there is enough width',
        (tester) async {
      final user = User(
        id: 'u2',
        lastname: 'Kone',
        firstname: 'Awa',
        phoneNumber: '+2250101010102',
        userType: UserType.staff,
        isStaff: true,
        internalProfile: const InternalProfile(
          id: 'p2',
          role: InternalRole.cashier,
          roleLabel: 'Caissier',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              child: StaffTopbar(
                user: user,
                title: 'Guichet',
                onLogout: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Awa Kone'), findsOneWidget);
      expect(find.text('Caissier'), findsOneWidget);
    });
  });
}
