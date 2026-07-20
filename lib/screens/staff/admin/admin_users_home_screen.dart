import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminUsersHomeScreen extends StatelessWidget {
  final User user;

  const AdminUsersHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(user.scopes);
    if (!permissions.canReadAdminUsers) {
      return const StaffAccessDeniedPage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffModuleHeader(
            icon: Icons.manage_accounts,
            title: 'Utilisateurs internes',
            description:
                'Administration des comptes personnel, rôles, gares et guichets.',
          ),
          const SizedBox(height: 14),
          StaffReadOnlyBanner(isReadOnly: !permissions.canManageAdminUsers),
          const SizedBox(height: 18),
          const StaffEmptyState(
            icon: Icons.manage_accounts,
            title: 'Module prêt à être complété',
            message:
                'La liste, le détail et les actions utilisateurs seront intégrés au lot 6.6C.',
          ),
        ],
      ),
    );
  }
}
