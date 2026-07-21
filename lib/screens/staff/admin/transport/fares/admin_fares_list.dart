import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminFaresList extends StatelessWidget {
  final PagedResult<AdminFare> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminFare> onOpenDetail;
  final ValueChanged<AdminFare> onReplace;
  final ValueChanged<AdminFare> onActivate;
  final ValueChanged<AdminFare> onDeactivate;

  const AdminFaresList(
      {super.key,
      required this.page,
      required this.canManage,
      required this.onPreviousPage,
      required this.onNextPage,
      required this.onOpenDetail,
      required this.onReplace,
      required this.onActivate,
      required this.onDeactivate});

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
                DataColumn(label: Text('Route')),
                DataColumn(label: Text('Classe')),
                DataColumn(label: Text('Montant')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Actions'))
              ],
              rows: page.results
                  .map((fare) => DataRow(cells: [
                        DataCell(Text(fare.route.displayLabel)),
                        DataCell(Text(_display(fare.serviceClass.name))),
                        DataCell(Text(fare.displayAmount)),
                        DataCell(
                            AdminTransportStatusBadge(isActive: fare.isActive)),
                        DataCell(_Actions(
                            fare: fare,
                            canManage: canManage,
                            onOpenDetail: onOpenDetail,
                            onReplace: onReplace,
                            onActivate: onActivate,
                            onDeactivate: onDeactivate))
                      ]))
                  .toList())));

  Widget _buildCards() => Column(
      children: page.results
          .map((fare) => Container(
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
                              child: Text(fare.route.displayLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          AdminTransportStatusBadge(isActive: fare.isActive)
                        ]),
                    const SizedBox(height: 8),
                    Text('Classe : ${_display(fare.serviceClass.name)}'),
                    Text('Montant : ${fare.displayAmount}'),
                    const SizedBox(height: 10),
                    Align(
                        alignment: Alignment.centerRight,
                        child: _Actions(
                            fare: fare,
                            canManage: canManage,
                            onOpenDetail: onOpenDetail,
                            onReplace: onReplace,
                            onActivate: onActivate,
                            onDeactivate: onDeactivate))
                  ])))
          .toList());
}

class _Actions extends StatelessWidget {
  final AdminFare fare;
  final bool canManage;
  final ValueChanged<AdminFare> onOpenDetail;
  final ValueChanged<AdminFare> onReplace;
  final ValueChanged<AdminFare> onActivate;
  final ValueChanged<AdminFare> onDeactivate;
  const _Actions(
      {required this.fare,
      required this.canManage,
      required this.onOpenDetail,
      required this.onReplace,
      required this.onActivate,
      required this.onDeactivate});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 4, children: [
        IconButton(
            key: Key('admin-fare-detail-${fare.id}'),
            tooltip: 'Détail',
            onPressed: () => onOpenDetail(fare),
            icon: const Icon(Icons.visibility_outlined)),
        if (canManage) ...[
          IconButton(
              key: Key('admin-fare-replace-${fare.id}'),
              tooltip: 'Remplacer le tarif',
              onPressed: () => onReplace(fare),
              icon: const Icon(Icons.price_change_outlined)),
          if (fare.isActive)
            IconButton(
                key: Key('admin-fare-deactivate-${fare.id}'),
                tooltip: 'Désactiver',
                onPressed: () => onDeactivate(fare),
                icon: const Icon(Icons.block, color: Color(0xFFB42318)))
          else
            IconButton(
                key: Key('admin-fare-activate-${fare.id}'),
                tooltip: 'Activer',
                onPressed: () => onActivate(fare),
                icon: const Icon(Icons.check_circle_outline,
                    color: Color(0xFF157347)))
        ]
      ]);
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
