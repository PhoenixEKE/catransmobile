import 'package:flutter/material.dart';

import 'package:catrans_app/widgets/staff/staff_action_group.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminRoutesList extends StatelessWidget {
  final PagedResult<AdminRoute> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminRoute> onOpenDetail;
  final ValueChanged<AdminRoute> onEdit;
  final ValueChanged<AdminRoute> onActivate;
  final ValueChanged<AdminRoute> onDeactivate;

  const AdminRoutesList({
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
        final cards = constraints.maxWidth < 860;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cards) _buildCards() else _buildTable(),
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

  Widget _buildTable() {
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
            DataColumn(label: Text('Compagnie')),
            DataColumn(label: Text('Départ')),
            DataColumn(label: Text('Ville départ')),
            DataColumn(label: Text('Destination')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((route) {
            return DataRow(
              cells: [
                DataCell(Text(_display(route.company.name))),
                DataCell(Text(_display(route.departureStation.name))),
                DataCell(Text(_display(route.departureCity?.name ??
                    route.departureStation.cityName))),
                DataCell(Text(route.displayDestination)),
                DataCell(AdminTransportStatusBadge(isActive: route.isActive)),
                DataCell(_Actions(
                  route: route,
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

  Widget _buildCards() {
    return Column(
      children: page.results.map((route) {
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
                    child: Text(
                      route.displayLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AdminTransportStatusBadge(isActive: route.isActive),
                ],
              ),
              const SizedBox(height: 8),
              Text('Compagnie : ${_display(route.company.name)}'),
              Text('Départ : ${_display(route.departureStation.name)}'),
              Text('Destination : ${route.displayDestination}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  route: route,
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
}

class _Actions extends StatelessWidget {
  final AdminRoute route;
  final bool canManage;
  final ValueChanged<AdminRoute> onOpenDetail;
  final ValueChanged<AdminRoute> onEdit;
  final ValueChanged<AdminRoute> onActivate;
  final ValueChanged<AdminRoute> onDeactivate;

  const _Actions({
    required this.route,
    required this.canManage,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return StaffActionGroup(
      children: [
        IconButton(
          key: Key('admin-route-detail-${route.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(route),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            key: Key('admin-route-edit-${route.id}'),
            tooltip: 'Modifier',
            onPressed: () => onEdit(route),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (route.isActive)
            IconButton(
              key: Key('admin-route-deactivate-${route.id}'),
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(route),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              key: Key('admin-route-activate-${route.id}'),
              tooltip: 'Activer',
              onPressed: () => onActivate(route),
              icon: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF157347),
              ),
            ),
        ],
      ],
    );
  }
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}