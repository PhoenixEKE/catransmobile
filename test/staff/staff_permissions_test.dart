import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';

void main() {
  group('StaffPermissions', () {
    test('manage scope implies read capability for admin users', () {
      final permissions = StaffPermissions.fromScopes(
        const [StaffPermissions.adminUsersManage],
      );

      expect(permissions.canReadAdminUsers, isTrue);
      expect(permissions.canManageAdminUsers, isTrue);
    });

    test('director-like read scopes remain read only', () {
      final permissions = StaffPermissions.fromScopes(const [
        StaffPermissions.adminUsersRead,
        StaffPermissions.adminTransportRead,
        StaffPermissions.adminOperationsRead,
        StaffPermissions.adminDashboardRead,
      ]);

      expect(permissions.canReadAdminUsers, isTrue);
      expect(permissions.canManageAdminUsers, isFalse);
      expect(permissions.canReadAdminTransport, isTrue);
      expect(permissions.canManageAdminTransport, isFalse);
      expect(permissions.canReadAdminOperations, isTrue);
      expect(permissions.canManageAdminOperations, isFalse);
      expect(permissions.canReadAdminDashboard, isTrue);
    });

    test('cashier cash scope does not grant admin modules', () {
      final permissions = StaffPermissions.fromScopes(
        const [StaffPermissions.stationSalesCash],
      );

      expect(permissions.canSellCashAtStation, isTrue);
      expect(permissions.canReadAdminUsers, isFalse);
      expect(permissions.canReadAdminTransport, isFalse);
      expect(permissions.canReadAdminOperations, isFalse);
      expect(permissions.canReadAdminDashboard, isFalse);
    });
  });
}
