import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/widgets/staff/staff_module_header.dart';

void main() {
  group('StaffModuleHeader trailing P0 fix', () {
    testWidgets('keeps the trailing widget on screen on a narrow (mobile) width',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StaffModuleHeader(
                icon: Icons.people,
                title: 'Utilisateurs internes',
                description: 'Gestion des comptes personnel.',
                trailing: const Chip(label: Text('12 comptes')),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Utilisateurs internes'), findsOneWidget);
      // Previously this was silently dropped below 640px — now it must
      // always be present, stacked under the title/description on mobile.
      expect(find.text('12 comptes'), findsOneWidget);
    });

    testWidgets('keeps the trailing widget on screen on a wide (desktop) width',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              child: StaffModuleHeader(
                icon: Icons.people,
                title: 'Utilisateurs internes',
                description: 'Gestion des comptes personnel.',
                trailing: const Chip(label: Text('12 comptes')),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('12 comptes'), findsOneWidget);
    });

    testWidgets('renders normally with no trailing at all', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StaffModuleHeader(
                icon: Icons.people,
                title: 'Utilisateurs internes',
                description: 'Gestion des comptes personnel.',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Utilisateurs internes'), findsOneWidget);
    });
  });
}
