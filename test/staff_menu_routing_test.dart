import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';

void main() {
  group('staff menu routing', () {
    test('cashier role with boarding scope only gets boarding module', () {
      final user = _internalUser(
        role: InternalRole.cashier,
        scopes: const ['boarding.validate'],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(_ids(menuItems), const ['boarding']);
      expect(_initialId(user, menuItems), 'boarding');
    });

    test('boarding role with counter scope does not get boarding from role',
        () {
      final user = _internalUser(
        role: InternalRole.station_agent,
        scopes: const ['station.reservations.search'],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(_ids(menuItems), const ['station_reservations']);
      expect(_initialId(user, menuItems), 'station_reservations');
    });

    test('admin role with reports scope only gets reports module', () {
      final user = _internalUser(
        role: InternalRole.admin,
        scopes: const ['station.reports.manage'],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(_ids(menuItems), const ['reports']);
      expect(_initialId(user, menuItems), 'reports');
    });

    test('dashboard and departures scopes build deterministic scope-only menu',
        () {
      final user = _internalUser(
        role: InternalRole.station_manager,
        scopes: const ['station.dashboard.read', 'station.departures.read'],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(_ids(menuItems), const ['home', 'departures']);
      expect(_initialId(user, menuItems), 'home');
    });

    test('cashier role with portal scopes gets the complete station portal', () {
      final user = _internalUser(
        role: InternalRole.cashier,
        scopes: const [
          'station.dashboard.read',
          'station.departures.read',
          'station.departures.depart',
          'station.reservations.search',
          'station.reservations.read',
          'station.sales.cash',
          'station.tickets.print',
          'station.tickets.read',
          'boarding.manifest.read',
          'boarding.validate',
          'boarding.summary.read',
        ],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(
        _ids(menuItems),
        const [
          'station_dashboard',
          'departures',
          'station_reservations',
          'boarding',
        ],
      );
      expect(_initialId(user, menuItems), 'station_dashboard');
    });

    test('unrecognized scopes with legacy cashier role use role fallback', () {
      final user = _internalUser(
        role: InternalRole.cashier,
        scopes: const ['legacy.unknown.scope'],
      );
      final menuItems = StaffMenuItem.forUser(user);

      expect(
        _ids(menuItems),
        const [
          'station_dashboard',
          'departures',
          'station_reservations',
          'boarding',
        ],
      );
      expect(_initialId(user, menuItems), 'station_dashboard');
    });

    test(
        'no scopes and no exploitable role returns empty menu and null initial',
        () {
      final user = _staffUserWithoutInternalProfile();
      final menuItems = StaffMenuItem.forUser(user);

      expect(menuItems, isEmpty);
      expect(_initialId(user, menuItems), isNull);
    });
  });
}

List<String> _ids(List<StaffMenuItem> items) {
  return items.map((item) => item.id).toList();
}

String? _initialId(User user, List<StaffMenuItem> menuItems) {
  return resolveInitialStaffMenuId(
    menuItems: menuItems,
    scopes: user.scopes.toSet(),
    role: user.internalProfile?.role,
  );
}

User _internalUser({
  required InternalRole role,
  List<String> scopes = const [],
}) {
  return User(
    id: 'user-${role.name}',
    lastname: 'Test',
    firstname: 'Staff',
    phoneNumber: '+2250101010101',
    userType: UserType.staff,
    isStaff: true,
    internalProfile: InternalProfile(
      id: 'profile-${role.name}',
      role: role,
      roleLabel: role.name,
    ),
    scopes: scopes,
  );
}

User _staffUserWithoutInternalProfile() {
  return User(
    id: 'user-no-profile',
    lastname: 'Test',
    firstname: 'Staff',
    phoneNumber: '+2250101010101',
    userType: UserType.staff,
    isStaff: true,
    scopes: [],
  );
}
