import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/client/profile/change_password_screen.dart';
import 'package:catrans_app/screens/client/profile/forgot_password_screen.dart';

void main() {
  group('password screens unavailable state', () {
    testWidgets('change password does not show a fake success flow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChangePasswordScreen()),
      );

      expect(
          find.text(ChangePasswordScreen.unavailableMessage), findsOneWidget);
      expect(find.text('Modification indisponible'), findsOneWidget);
      expect(find.text('Email envoyé'), findsNothing);
      expect(find.text('ENVOYER L\'EMAIL DE CONFIRMATION'), findsNothing);
      expect(find.text('RETOUR'), findsOneWidget);
    });

    testWidgets('forgot password does not show a fake reset email flow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      expect(
          find.text(ForgotPasswordScreen.unavailableMessage), findsOneWidget);
      expect(find.text('Récupération indisponible'), findsOneWidget);
      expect(find.text('Email envoyé'), findsNothing);
      expect(find.text('ENVOYER LE LIEN'), findsNothing);
      expect(find.text('RETOUR'), findsOneWidget);
    });
  });
}
