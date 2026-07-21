import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_badges.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminUsersList extends StatelessWidget {
  final PagedResult<AdminInternalUserSummary> page;
  final int currentPage;
  final int pageSize;
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
    required this.currentPage,
    required this.pageSize,
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
            if (useCards)
              KeyedSubtree(
                key: const Key('admin-users-cards-view'),
                child: _buildCards(context),
              )
            else
              KeyedSubtree(
                key: const Key('admin-users-table-view'),
                child: _buildTable(context),
              ),
            const SizedBox(height: 10),
            Text(
              'Page $currentPage · ${page.results.length} résultat(s) affiché(s) sur ${page.count} (taille page $pageSize)',
              style: const TextStyle(
                color: Color(0xFF656A78),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
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
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Téléphone')),
            DataColumn(label: Text('Rôle')),
            DataColumn(label: Text('Gare')),
            DataColumn(label: Text('Guichet')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Créé le')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((user) {
            return DataRow(
              cells: [
                DataCell(_ellipsized(_displayName(user), width: 160)),
                DataCell(_ellipsized(user.email.isEmpty ? '-' : user.email,
                    width: 200)),
                DataCell(_ellipsized(
                    user.phoneNumber.isEmpty ? '-' : user.phoneNumber,
                    width: 140)),
                DataCell(AdminUserRoleBadge(label: user.roleLabel)),
                DataCell(_ellipsized(user.station?.name ?? '-', width: 150)),
                DataCell(_ellipsized(user.counter?.label ?? '-', width: 150)),
                DataCell(AdminUserStatusBadge(isActive: user.isActive)),
                DataCell(Text(_formatDate(user.createdAt))),
                DataCell(_ActionsMenu(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.email.isEmpty ? '-' : user.email,
                          style: const TextStyle(color: Color(0xFF656A78)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber.isEmpty ? '-' : user.phoneNumber,
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
              Text('Créé le : ${_formatDate(user.createdAt)}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _ActionsMenu(
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

Widget _ellipsized(String value, {required double width}) {
  return SizedBox(
    width: width,
    child: Tooltip(
      message: value,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

class _ActionsMenu extends StatelessWidget {
  final AdminInternalUserSummary user;
  final bool canManage;
  final ValueChanged<AdminInternalUserSummary> onOpenDetail;
  final ValueChanged<AdminInternalUserSummary> onEdit;
  final ValueChanged<AdminInternalUserSummary> onActivate;
  final ValueChanged<AdminInternalUserSummary> onDeactivate;

  const _ActionsMenu({
    required this.user,
    required this.canManage,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: Key('admin-users-actions-${user.id}'),
      tooltip: 'Actions utilisateur',
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        switch (value) {
          case 'detail':
            onOpenDetail(user);
            return;
          case 'edit':
            onEdit(user);
            return;
          case 'activate':
            onActivate(user);
            return;
          case 'deactivate':
            onDeactivate(user);
            return;
        }
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'detail',
            child: Text('Consulter'),
          ),
        ];
        if (canManage) {
          items.add(
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Modifier'),
            ),
          );
          items.add(
            PopupMenuItem<String>(
              value: user.isActive ? 'deactivate' : 'activate',
              child: Text(user.isActive ? 'Désactiver' : 'Activer'),
            ),
          );
        }
        return items;
      },
    );
  }
}
