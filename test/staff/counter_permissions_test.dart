import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/screens/staff/counter/counter_permissions.dart';

void main() {
  test('counter sales cash scope helper', () {
    expect(hasCounterSalesCashScope(const ['station.sales.cash']), isTrue);
    expect(
        hasCounterSalesCashScope(const ['station.reservations.read']), isFalse);
  });

  test('counter print helper uses backend gate and scope gate', () {
    expect(
      canPrintCounterTicket(
        hasPrintScope: true,
        backendAllowsPrint: true,
      ),
      isTrue,
    );
    expect(
      canPrintCounterTicket(
        hasPrintScope: false,
        backendAllowsPrint: true,
      ),
      isFalse,
    );
  });
}
