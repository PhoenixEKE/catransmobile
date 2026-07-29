import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminServiceClassesList extends StatelessWidget {
  final PagedResult<AdminServiceClass> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminServiceClass> onOpenDetail;
  final ValueChanged<AdminServiceClass> onEdit;
  final ValueChanged<AdminServiceClass> onActivate;
  final ValueChanged<AdminServiceClass> onDeactivate;

  const AdminServiceClassesList({
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
        final useCards = constraints.maxWidth < 820;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (useCards)
              KeyedSubtree(
                key: const Key('admin-service-classes-list-view'),
                child: _buildCards(),
              )
            else
              KeyedSubtree(
                key: const Key('admin-service-classes-table-view'),
                child: _buildTable(),
              ),
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
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Points')),
            DataColumn(label: Text('Sièges')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((serviceClass) {
            return DataRow(
              cells: [
                DataCell(
                    Text(serviceClass.code.isEmpty ? '-' : serviceClass.code)),
                DataCell(
                    Text(serviceClass.name.isEmpty ? '-' : serviceClass.name)),
                DataCell(Text(serviceClass.defaultLoyaltyPoints.toString())),
                DataCell(Text(serviceClass.allowsSeatSelection
                    ? 'Manuelle'
                    : 'Automatique')),
                DataCell(
                    AdminTransportStatusBadge(isActive: serviceClass.isActive)),
                DataCell(_Actions(
                  serviceClass: serviceClass,
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
      children: page.results.map((serviceClass) {
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
                      '${serviceClass.code} · ${serviceClass.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  AdminTransportStatusBadge(isActive: serviceClass.isActive),
                ],
              ),
              const SizedBox(height: 8),
              Text('Points : ${serviceClass.defaultLoyaltyPoints}'),
              Text(
                  'Sélection siège : ${serviceClass.allowsSeatSelection ? 'manuelle' : 'automatique'}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  serviceClass: serviceClass,
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
  final AdminServiceClass serviceClass;
  final bool canManage;
  final ValueChanged<AdminServiceClass> onOpenDetail;
  final ValueChanged<AdminServiceClass> onEdit;
  final ValueChanged<AdminServiceClass> onActivate;
  final ValueChanged<AdminServiceClass> onDeactivate;

  const _Actions({
    required this.serviceClass,
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
          key: Key('admin-service-class-detail-${serviceClass.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(serviceClass),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            key: Key('admin-service-class-edit-${serviceClass.id}'),
            tooltip: 'Modifier',
            onPressed: () => onEdit(serviceClass),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (serviceClass.isActive)
            IconButton(
              key: Key('admin-service-class-deactivate-${serviceClass.id}'),
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(serviceClass),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              key: Key('admin-service-class-activate-${serviceClass.id}'),
              tooltip: 'Activer',
              onPressed: () => onActivate(serviceClass),
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
