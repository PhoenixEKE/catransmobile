import 'package:flutter/material.dart';

import 'package:catrans_app/widgets/staff/staff_action_group.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_counter_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminCountersList extends StatelessWidget {
  final PagedResult<AdminStationCounter> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminStationCounter> onOpenDetail;
  final ValueChanged<AdminStationCounter> onEdit;
  final ValueChanged<AdminStationCounter> onActivate;
  final ValueChanged<AdminStationCounter> onDeactivate;

  const AdminCountersList({
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
        final cards = constraints.maxWidth < 760;
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
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Libellé')),
            DataColumn(label: Text('Gare')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((counter) {
            return DataRow(
              cells: [
                DataCell(Text(_display(counter.code))),
                DataCell(Text(_display(counter.label))),
                DataCell(Text(_display(counter.station.name))),
                DataCell(AdminTransportStatusBadge(isActive: counter.isActive)),
                DataCell(_Actions(
                  counter: counter,
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
      children: page.results.map((counter) {
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
                      '${_display(counter.code)} · ${_display(counter.label)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AdminTransportStatusBadge(isActive: counter.isActive),
                ],
              ),
              const SizedBox(height: 8),
              Text('Gare : ${_display(counter.station.name)}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  counter: counter,
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
  final AdminStationCounter counter;
  final bool canManage;
  final ValueChanged<AdminStationCounter> onOpenDetail;
  final ValueChanged<AdminStationCounter> onEdit;
  final ValueChanged<AdminStationCounter> onActivate;
  final ValueChanged<AdminStationCounter> onDeactivate;

  const _Actions({
    required this.counter,
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
          key: Key('admin-counter-detail-${counter.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(counter),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            key: Key('admin-counter-edit-${counter.id}'),
            tooltip: 'Modifier',
            onPressed: () => onEdit(counter),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (counter.isActive)
            IconButton(
              key: Key('admin-counter-deactivate-${counter.id}'),
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(counter),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              key: Key('admin-counter-activate-${counter.id}'),
              tooltip: 'Activer',
              onPressed: () => onActivate(counter),
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
