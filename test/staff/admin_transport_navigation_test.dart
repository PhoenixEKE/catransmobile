import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/admin/transport/admin_transport_navigation.dart';

void main() {
  group('admin transport navigation', () {
    testWidgets('shows companies as available and future sections disabled',
        (tester) async {
      String selected = 'companies';
      await tester.binding.setSurfaceSize(const Size(360, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AdminTransportNavigation(
                  selectedSectionId: selected,
                  sections: const [
                    AdminTransportSection(
                      id: 'companies',
                      label: 'Compagnies',
                      icon: Icons.business,
                      isAvailable: true,
                    ),
                    AdminTransportSection(
                      id: 'cities',
                      label: 'Villes',
                      icon: Icons.location_city,
                    ),
                  ],
                  onSectionSelected: (sectionId) {
                    setState(() => selected = sectionId);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Compagnies'), findsOneWidget);
      expect(find.text('Villes · à venir'), findsOneWidget);
      await tester.tap(find.text('Villes · à venir'), warnIfMissed: false);
      await tester.pump();

      expect(selected, 'companies');
    });
  });
}
