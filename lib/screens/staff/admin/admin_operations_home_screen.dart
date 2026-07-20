import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminOperationsHomeScreen extends StatelessWidget {
  final User user;

  const AdminOperationsHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(user.scopes);
    if (!permissions.canReadAdminOperations) {
      return const StaffAccessDeniedPage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffModuleHeader(
            icon: Icons.event_seat,
            title: 'Opérations admin',
            description:
                'Layouts, templates, zones de classe, génération de départs et sièges.',
          ),
          const SizedBox(height: 14),
          StaffReadOnlyBanner(
              isReadOnly: !permissions.canManageAdminOperations),
          const SizedBox(height: 18),
          const StaffEmptyState(
            icon: Icons.event_seat,
            title: 'Fondation opérations disponible',
            message:
                'Les écrans opérationnels administrateur seront complétés au lot 6.6E.',
          ),
        ],
      ),
    );
  }
}
