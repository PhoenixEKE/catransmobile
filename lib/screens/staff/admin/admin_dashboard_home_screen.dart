import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';

class AdminDashboardHomeScreen extends StatelessWidget {
  final User user;

  const AdminDashboardHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(user.scopes);
    if (!permissions.canReadAdminDashboard) {
      return const StaffAccessDeniedPage();
    }

    return const _AdminEntryScaffold(
      icon: Icons.query_stats,
      title: 'Tableau de bord admin',
      description:
          'Vue de pilotage globale CA TRANS pour la direction et l’administration.',
      child: StaffEmptyState(
        icon: Icons.query_stats,
        title: 'Fondation prête',
        message:
            'Les indicateurs globaux seront branchés depuis les endpoints admin dashboard au prochain lot dédié.',
      ),
    );
  }
}

class _AdminEntryScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  const _AdminEntryScaffold({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffModuleHeader(icon: icon, title: title, description: description),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
