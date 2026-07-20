import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminTransportHomeScreen extends StatelessWidget {
  final User user;

  const AdminTransportHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final permissions = StaffPermissions.fromScopes(user.scopes);
    if (!permissions.canReadAdminTransport) {
      return const StaffAccessDeniedPage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StaffModuleHeader(
            icon: Icons.route,
            title: 'Référentiels transport',
            description:
                'Compagnies, villes, gares, guichets, classes, routes, tarifs et horaires.',
          ),
          const SizedBox(height: 14),
          StaffReadOnlyBanner(isReadOnly: !permissions.canManageAdminTransport),
          const SizedBox(height: 18),
          const StaffEmptyState(
            icon: Icons.route,
            title: 'Fondation transport disponible',
            message:
                'Les vues de gestion des référentiels seront ajoutées progressivement au lot 6.6D.',
          ),
        ],
      ),
    );
  }
}
