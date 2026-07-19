import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/main.dart';

void main() {
  testWidgets('CA TRANS app starts without throwing', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Voyagez sans stress'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
