import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/counter/counter_permissions.dart';

void main() {
  group('counter ticket print permissions', () {
    test('read scope alone never allows printing', () {
      expect(
        hasCounterTicketPrintScope(const ['station.tickets.read']),
        isFalse,
      );
      expect(
        canPrintCounterTicket(
          hasPrintScope: hasCounterTicketPrintScope(
            const ['station.tickets.read'],
          ),
          backendAllowsPrint: true,
        ),
        isFalse,
      );
    });

    test('print scope without backend action does not allow printing', () {
      expect(
        canPrintCounterTicket(
          hasPrintScope: hasCounterTicketPrintScope(
            const ['station.tickets.print'],
          ),
          backendAllowsPrint: false,
        ),
        isFalse,
      );
    });

    test('print scope and backend action allow printing', () {
      expect(
        canPrintCounterTicket(
          hasPrintScope: hasCounterTicketPrintScope(
            const ['station.tickets.print'],
          ),
          backendAllowsPrint: true,
        ),
        isTrue,
      );
    });

    test('no print scope and no backend action does not allow printing', () {
      expect(
        canPrintCounterTicket(
          hasPrintScope: hasCounterTicketPrintScope(const []),
          backendAllowsPrint: false,
        ),
        isFalse,
      );
    });
  });
}
