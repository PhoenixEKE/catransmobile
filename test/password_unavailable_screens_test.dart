import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/screens/client/profile/change_password_screen.dart';
import 'package:catrans_app/screens/client/profile/forgot_password_screen.dart';
import 'package:catrans_app/services/api/auth_api_service.dart';
import 'package:catrans_app/services/auth_service.dart';

void main() {
  group('change password real form', () {
    testWidgets('shows a real form instead of the unavailable placeholder',
        (tester) async {
      final authService = AuthService(
        authApiService: AuthApiService(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/')),
          ),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: ChangePasswordScreen()),
        ),
      );

      expect(find.text('Mot de passe actuel'), findsOneWidget);
      expect(find.text('Nouveau mot de passe'), findsOneWidget);
      expect(find.text('Confirmer le nouveau mot de passe'), findsOneWidget);
      expect(find.text('ENREGISTRER'), findsOneWidget);
      expect(find.text('Modification indisponible'), findsNothing);
      expect(find.text('RETOUR'), findsNothing);
    });

    testWidgets('rejects empty submission locally without calling the API',
        (tester) async {
      final authService = AuthService(
        authApiService: AuthApiService(
          apiClient: ApiClient(
            dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1/')),
          ),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthService>.value(
          value: authService,
          child: const MaterialApp(home: ChangePasswordScreen()),
        ),
      );

      await tester.tap(find.text('ENREGISTRER'));
      await tester.pump();

      expect(
        find.text('Veuillez entrer votre mot de passe actuel'),
        findsOneWidget,
      );
      expect(
        find.text('Veuillez entrer un nouveau mot de passe'),
        findsOneWidget,
      );
    });
  });

  group('forgot password screen unavailable state', () {
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
