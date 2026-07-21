import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/admin/operations/admin_operations_navigation.dart';

void main() {
  testWidgets('shows operations sections and changes selected section',
      (tester) async {
    String selected = 'departures';
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => AdminOperationsNavigation(
            selectedSectionId: selected,
            sections: const [
              AdminOperationsSection(
                id: 'departures',
                label: 'Départs',
                icon: Icons.directions_bus_outlined,
              ),
              AdminOperationsSection(
                id: 'seats',
                label: 'Sièges',
                icon: Icons.event_seat_outlined,
              ),
              AdminOperationsSection(
                id: 'boarding',
                label: 'Embarquement',
                icon: Icons.qr_code_scanner,
              ),
            ],
            onSectionSelected: (sectionId) =>
                setState(() => selected = sectionId),
          ),
        ),
      ),
    ));

    expect(find.text('Départs'), findsOneWidget);
    expect(find.text('Sièges'), findsOneWidget);
    expect(find.text('Embarquement'), findsOneWidget);

    await tester.tap(find.text('Sièges'));
    await tester.pump();
    expect(selected, 'seats');

    await tester.tap(find.text('Embarquement'));
    await tester.pump();
    expect(selected, 'boarding');
  });
}
