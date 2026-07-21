import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/admin/transport/admin_transport_navigation.dart';

void main() {
  group('admin transport navigation', () {
    testWidgets(
        'shows active transport references and keeps schedules disabled',
        (tester) async {
      String selected = 'companies';
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        return AdminTransportNavigation(
          selectedSectionId: selected,
          sections: const [
            AdminTransportSection(
                id: 'companies',
                label: 'Compagnies',
                icon: Icons.business,
                isAvailable: true),
            AdminTransportSection(
                id: 'cities',
                label: 'Villes',
                icon: Icons.location_city,
                isAvailable: true),
            AdminTransportSection(
                id: 'stations',
                label: 'Gares',
                icon: Icons.store_mall_directory,
                isAvailable: true),
            AdminTransportSection(
                id: 'counters',
                label: 'Guichets',
                icon: Icons.point_of_sale,
                isAvailable: true),
            AdminTransportSection(
                id: 'service_classes',
                label: 'Classes',
                icon: Icons.airline_seat_recline_extra,
                isAvailable: true),
            AdminTransportSection(
                id: 'routes',
                label: 'Routes',
                icon: Icons.alt_route,
                isAvailable: true),
            AdminTransportSection(
                id: 'fares',
                label: 'Tarifs',
                icon: Icons.payments,
                isAvailable: true),
            AdminTransportSection(
                id: 'schedules', label: 'Horaires', icon: Icons.schedule),
          ],
          onSectionSelected: (sectionId) =>
              setState(() => selected = sectionId),
        );
      }))));

      for (final label in [
        'Compagnies',
        'Villes',
        'Gares',
        'Guichets',
        'Classes',
        'Routes',
        'Tarifs'
      ]) {
        expect(find.text(label), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(selected, 'fares');
      expect(find.text('Horaires · à venir'), findsOneWidget);
      await tester.tap(find.text('Horaires · à venir'));
      await tester.pump();
      expect(selected, 'fares');
    });
  });
}
