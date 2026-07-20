import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_badges.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminUsersList extends StatelessWidget {
  final PagedResult<AdminInternalUserSummary> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminInternalUserSummary> onOpenDetail;
  final ValueChanged<AdminInternalUserSummary> onEdit;
  final ValueChanged<AdminInternalUserSummary> onActivate;
  final ValueChanged<AdminInternalUserSummary> onDeactivate;

  const AdminUsersList({
    super.key,
    required this.page,
    required this.canManage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (useCards) _buildCards(context) else _buildTable(context),
            const SizedBox(height: 10),
            StaffPaginationControls(
              hasPrevious: page.hasPrevious,
              hasNext: page.hasNext,
              onPrevious: onPreviousPage,
              onNext: onNextPage,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Rôle')),
            DataColumn(label: Text('Gare')),
            DataColumn(label: Text('Guichet')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((user) {
            return DataRow(
              cells: [
                DataCell(Text(_displayName(user))),
                DataCell(Text(user.email.isEmpty ? '-' : user.email)),
                DataCell(AdminUserRoleBadge(label: user.roleLabel)),
                DataCell(Text(user.station?.name ?? '-')),
                DataCell(Text(user.counter?.label ?? '-')),
                DataCell(AdminUserStatusBadge(isActive: user.isActive)),
                DataCell(_Actions(
                  user: user,
                  canManage: canManage,
                  onOpenDetail: onOpenDetail,
                  onEdit: onEdit,
                  onActivate: onActivate,
                  onDeactivate: onDeactivate,
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return Column(
      children: page.results.map((user) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E7EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(user),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email.isEmpty ? '-' : user.email,
                          style: const TextStyle(color: Color(0xFF656A78)),
                        ),
                      ],
                    ),
                  ),
                  AdminUserStatusBadge(isActive: user.isActive),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminUserRoleBadge(label: user.roleLabel),
                  AdminUserAssignmentBadge(
                    isIncomplete: _isAssignmentIncomplete(user),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Gare : ${user.station?.name ?? '-'}'),
              Text('Guichet : ${user.counter?.label ?? '-'}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  user: user,
                  canManage: canManage,
                  onOpenDetail: onOpenDetail,
                  onEdit: onEdit,
                  onActivate: onActivate,
                  onDeactivate: onDeactivate,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _displayName(AdminInternalUserSummary user) {
    final name = user.fullName;
    if (name.isNotEmpty) return name;
    return user.email.isEmpty ? 'Utilisateur interne' : user.email;
  }

  bool _isAssignmentIncomplete(AdminInternalUserSummary user) {
    final stationRole = user.role == 'station_manager' ||
        user.role == 'station_agent' ||
        user.role == 'cashier';
    if (!stationRole) return false;
    if (user.station == null) return true;
    if (user.role == 'cashier' && user.counter == null) return true;
    return false;
  }
}

class _Actions extends StatelessWidget {
  final AdminInternalUserSummary user;
  final bool canManage;
  final ValueChanged<AdminInternalUserSummary> onOpenDetail;
  final ValueChanged<AdminInternalUserSummary> onEdit;
  final ValueChanged<AdminInternalUserSummary> onActivate;
  final ValueChanged<AdminInternalUserSummary> onDeactivate;

  const _Actions({
    required this.user,
    required this.canManage,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(user),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            tooltip: 'Modifier',
            onPressed: () => onEdit(user),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (user.isActive)
            IconButton(
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(user),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              tooltip: 'Activer',
              onPressed: () => onActivate(user),
              icon: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF157347)),
            ),
        ],
      ],
    );
  }
}
