import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminSchedulesList extends StatelessWidget {
  final PagedResult<AdminSchedule> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminSchedule> onOpenDetail;
  final ValueChanged<AdminSchedule> onEdit;
  final ValueChanged<AdminSchedule> onActivate;
  final ValueChanged<AdminSchedule> onDeactivate;

  const AdminSchedulesList({
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
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
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
                  onNext: onNextPage)
            ]);
      });

  Widget _buildTable() => Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EF))),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
              columns: const [
                DataColumn(label: Text('Gare')),
                DataColumn(label: Text('Route')),
                DataColumn(label: Text('Classe')),
                DataColumn(label: Text('Heure')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Actions'))
              ],
              rows: page.results
                  .map((schedule) => DataRow(cells: [
                        DataCell(Text(_display(schedule.station.name))),
                        DataCell(Text(schedule.displayRoute)),
                        DataCell(Text(schedule.displayServiceClass)),
                        DataCell(Text(schedule.displayTime)),
                        DataCell(AdminTransportStatusBadge(
                            isActive: schedule.isActive)),
                        DataCell(_Actions(
                            schedule: schedule,
                            canManage: canManage,
                            onOpenDetail: onOpenDetail,
                            onEdit: onEdit,
                            onActivate: onActivate,
                            onDeactivate: onDeactivate))
                      ]))
                  .toList())));

  Widget _buildCards() => Column(
      children: page.results
          .map((schedule) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E7EF))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(schedule.displayRoute,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          AdminTransportStatusBadge(
                              isActive: schedule.isActive)
                        ]),
                    const SizedBox(height: 8),
                    Text('Gare : ${_display(schedule.station.name)}'),
                    Text('Classe : ${schedule.displayServiceClass}'),
                    Text('Heure : ${schedule.displayTime}'),
                    if (_display(schedule.routeNote) != '-')
                      Text('Note : ${_display(schedule.routeNote)}'),
                    const SizedBox(height: 10),
                    Align(
                        alignment: Alignment.centerRight,
                        child: _Actions(
                            schedule: schedule,
                            canManage: canManage,
                            onOpenDetail: onOpenDetail,
                            onEdit: onEdit,
                            onActivate: onActivate,
                            onDeactivate: onDeactivate))
                  ])))
          .toList());
}

class _Actions extends StatelessWidget {
  final AdminSchedule schedule;
  final bool canManage;
  final ValueChanged<AdminSchedule> onOpenDetail;
  final ValueChanged<AdminSchedule> onEdit;
  final ValueChanged<AdminSchedule> onActivate;
  final ValueChanged<AdminSchedule> onDeactivate;

  const _Actions({
    required this.schedule,
    required this.canManage,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) => Wrap(spacing: 4, children: [
        IconButton(
            key: Key('admin-schedule-detail-${schedule.id}'),
            tooltip: 'Détail',
            onPressed: () => onOpenDetail(schedule),
            icon: const Icon(Icons.visibility_outlined)),
        if (canManage) ...[
          IconButton(
              key: Key('admin-schedule-edit-${schedule.id}'),
              tooltip: 'Modifier',
              onPressed: () => onEdit(schedule),
              icon: const Icon(Icons.edit_outlined)),
          if (schedule.isActive)
            IconButton(
                key: Key('admin-schedule-deactivate-${schedule.id}'),
                tooltip: 'Désactiver',
                onPressed: () => onDeactivate(schedule),
                icon: const Icon(Icons.block, color: Color(0xFFB42318)))
          else
            IconButton(
                key: Key('admin-schedule-activate-${schedule.id}'),
                tooltip: 'Activer',
                onPressed: () => onActivate(schedule),
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF157347)))
        ]
      ]);
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
