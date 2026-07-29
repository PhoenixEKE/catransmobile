import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/navigation/app_router.dart';
import 'package:catrans_app/main.dart';
import 'package:catrans_app/services/auth_service.dart';

void main() {
  testWidgets('CA TRANS app starts without throwing', (tester) async {
    final authService = AuthService();
    await tester.pumpWidget(
      MyApp(authService: authService, router: buildAppRouter(authService)),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Voyagez sans stress'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
