import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/client/auth/splash_screen.dart';

void main() {
  group('public traveller entry screen (AuthChoiceScreen)', () {
    testWidgets('no longer exposes an Administration entry point',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthChoiceScreen()));

      expect(find.text('Administration'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
    });

    testWidgets('still offers the traveller actions', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthChoiceScreen()));

      expect(find.text('SE CONNECTER'), findsOneWidget);
      expect(find.text('CRÉER UN COMPTE'), findsOneWidget);
    });
  });
}
