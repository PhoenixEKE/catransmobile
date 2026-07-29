import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';

void main() {
  test('cashier sees only the supported menu items', () {
    final user = User(
      id: 'user-1',
      lastname: 'Cash',
      firstname: 'Agent',
      phoneNumber: '00000000',
      userType: UserType.staff,
      internalProfile: const InternalProfile(
        id: 'profile-1',
        role: InternalRole.cashier,
        roleLabel: 'Caissier',
      ),
      scopes: const [
        'station.dashboard.read',
        'station.reservations.search',
        'station.tickets.print',
        'station.sales.cash',
        'station.departures.read',
        'station.departures.depart',
        'boarding.manifest.read',
        'boarding.validate',
        'boarding.summary.read',
      ],
    );

    final items = StaffMenuItem.forUser(user);

    expect(items.map((item) => item.id).toList(), [
      'station_dashboard',
      'departures',
      'station_reservations',
      'boarding',
    ]);
    expect(items.any((item) => item.id == 'counter_reports'), isFalse);
    expect(
      resolveInitialStaffMenuId(
        menuItems: items,
        scopes: user.scopes.toSet(),
        role: user.internalProfile?.role,
      ),
      'station_dashboard',
    );
  });
}
