import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminStationsList extends StatelessWidget {
  final PagedResult<AdminStation> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminStation> onOpenDetail;
  final ValueChanged<AdminStation> onEdit;
  final ValueChanged<AdminStation> onActivate;
  final ValueChanged<AdminStation> onDeactivate;

  const AdminStationsList({super.key, required this.page, required this.canManage, required this.onPreviousPage, required this.onNextPage, required this.onOpenDetail, required this.onEdit, required this.onActivate, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cards = constraints.maxWidth < 860;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (cards) _buildCards() else _buildTable(),
        const SizedBox(height: 10),
        StaffPaginationControls(hasPrevious: page.hasPrevious, hasNext: page.hasNext, onPrevious: onPreviousPage, onNext: onNextPage),
      ]);
    });
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E7EF))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FC)),
          columns: const [DataColumn(label: Text('Nom')), DataColumn(label: Text('Compagnie')), DataColumn(label: Text('Ville')), DataColumn(label: Text('Code')), DataColumn(label: Text('Statut')), DataColumn(label: Text('Actions'))],
          rows: page.results.map((station) => DataRow(cells: [
            DataCell(Text(_display(station.name))),
            DataCell(Text(_display(station.company.name))),
            DataCell(Text(_display(station.cityName))),
            DataCell(Text(_display(station.code))),
            DataCell(AdminTransportStatusBadge(isActive: station.isActive)),
            DataCell(_Actions(station: station, canManage: canManage, onOpenDetail: onOpenDetail, onEdit: onEdit, onActivate: onActivate, onDeactivate: onDeactivate)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildCards() {
    return Column(children: page.results.map((station) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E7EF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(_display(station.name), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), AdminTransportStatusBadge(isActive: station.isActive)]),
        const SizedBox(height: 8),
        Text('Compagnie : ${_display(station.company.name)}'),
        Text('Ville : ${_display(station.cityName)}'),
        Text('Code : ${_display(station.code)}'),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: _Actions(station: station, canManage: canManage, onOpenDetail: onOpenDetail, onEdit: onEdit, onActivate: onActivate, onDeactivate: onDeactivate)),
      ]),
    )).toList());
  }
}

class _Actions extends StatelessWidget {
  final AdminStation station;
  final bool canManage;
  final ValueChanged<AdminStation> onOpenDetail;
  final ValueChanged<AdminStation> onEdit;
  final ValueChanged<AdminStation> onActivate;
  final ValueChanged<AdminStation> onDeactivate;

  const _Actions({required this.station, required this.canManage, required this.onOpenDetail, required this.onEdit, required this.onActivate, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 4, children: [
      IconButton(key: Key('admin-station-detail-${station.id}'), tooltip: 'Détail', onPressed: () => onOpenDetail(station), icon: const Icon(Icons.visibility_outlined)),
      if (canManage) ...[
        IconButton(key: Key('admin-station-edit-${station.id}'), tooltip: 'Modifier', onPressed: () => onEdit(station), icon: const Icon(Icons.edit_outlined)),
        if (station.isActive) IconButton(key: Key('admin-station-deactivate-${station.id}'), tooltip: 'Désactiver', onPressed: () => onDeactivate(station), icon: const Icon(Icons.block, color: Color(0xFFB42318))) else IconButton(key: Key('admin-station-activate-${station.id}'), tooltip: 'Activer', onPressed: () => onActivate(station), icon: const Icon(Icons.check_circle_outline, color: Color(0xFF157347))),
      ],
    ]);
  }
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
