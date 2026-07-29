import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/admin/operations/boarding/admin_boarding_confirmation_dialog.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_helpers.dart';

void main() {
  testWidgets('boarding confirmation returns true when confirmed',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final future = showAdminBoardingConfirmationDialog(
      context: tester.element(find.byType(Scaffold)),
      identifier: 'TCK-ABC123',
      isToken: false,
      isSubmitting: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-boarding-confirm')));
    await tester.pumpAndSettle();

    expect(await future, isTrue);
  });

  test('boarding presentation maps accepted result', () {
    const validation = StationTicketValidation(
      id: 'v1',
      status: 'accepted',
      statusLabel: 'Accepté',
      channel: 'station_agent',
      channelLabel: 'Agent gare',
      resultMessage: 'Ticket accepté.',
    );

    final presentation = presentationForValidation(validation);
    expect(presentation.isSuccess, isTrue);
    expect(presentation.title, 'Billet validé');
  });
}
