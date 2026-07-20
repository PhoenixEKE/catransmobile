import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/admin/transport/admin_transport_navigation.dart';

void main() {
  group('admin transport navigation', () {
    testWidgets('shows active transport sections and keeps future sections disabled',
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
                      isAvailable: true,
                    ),
                    AdminTransportSection(
                      id: 'service_classes',
                      label: 'Classes',
                      icon: Icons.airline_seat_recline_extra,
                      isAvailable: true,
                    ),
                    AdminTransportSection(
                      id: 'routes',
                      label: 'Routes',
                      icon: Icons.alt_route,
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
      expect(find.text('Villes'), findsOneWidget);
      expect(find.text('Classes'), findsOneWidget);
      expect(find.text('Routes · à venir'), findsOneWidget);

      await tester.tap(find.text('Villes'));
      await tester.pump();
      expect(selected, 'cities');

      await tester.tap(find.text('Classes'));
      await tester.pump();
      expect(selected, 'service_classes');

      await tester.tap(find.text('Routes · à venir'));
      await tester.pump();
      expect(selected, 'service_classes');
    });
  });
}
