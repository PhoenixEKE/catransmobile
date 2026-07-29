import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_departure_not_open_badge.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_departure_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminDeparturesList extends StatelessWidget {
  final PagedResult<AdminDeparture> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminDeparture> onOpenDetail;
  final ValueChanged<AdminDeparture> onOpenSeats;
  final ValueChanged<AdminDeparture> onOpenBoarding;
  final ValueChanged<AdminDeparture> onEditDate;
  final void Function(AdminDeparture departure, String action) onTransition;

  const AdminDeparturesList({
    super.key,
    required this.page,
    required this.canManage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onOpenDetail,
    required this.onOpenSeats,
    required this.onOpenBoarding,
    required this.onEditDate,
    required this.onTransition,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = constraints.maxWidth < 880;
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
            DataColumn(label: Text('Départ')),
            DataColumn(label: Text('Route')),
            DataColumn(label: Text('Gare')),
            DataColumn(label: Text('Classe')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((departure) {
            return DataRow(
              cells: [
                DataCell(Text(departure.displaySchedule)),
                DataCell(Text(departure.displayRoute)),
                DataCell(Text(departure.displayStation)),
                DataCell(Text(departure.displayClass)),
                DataCell(Row(
                  // DataTable rows have a fixed height: a Wrap that drops to
                  // a second line here (as it did once both badges no longer
                  // fit side by side) overflows past that fixed height and
                  // paints over the row below. A Row never wraps - the
                  // Statut column just grows wider instead, which is safe
                  // since the whole table already scrolls horizontally.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminDepartureStatusBadge(
                      code: departure.status.code,
                      label: departure.status.label,
                    ),
                    if (departure.status.code == 'scheduled') ...[
                      const SizedBox(width: 6),
                      const AdminDepartureNotOpenBadge(),
                    ],
                  ],
                )),
                DataCell(_Actions(
                  departure: departure,
                  canManage: canManage,
                  onOpenDetail: onOpenDetail,
                  onOpenSeats: onOpenSeats,
                  onOpenBoarding: onOpenBoarding,
                  onEditDate: onEditDate,
                  onTransition: onTransition,
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
      children: page.results.map((departure) {
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
                      departure.displaySchedule,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AdminDepartureStatusBadge(
                    code: departure.status.code,
                    label: departure.status.label,
                  ),
                ],
              ),
              if (departure.status.code == 'scheduled') ...[
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AdminDepartureNotOpenBadge(),
                ),
              ],
              const SizedBox(height: 8),
              Text(departure.displayRoute),
              Text('${departure.displayStation} · ${departure.displayClass}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  departure: departure,
                  canManage: canManage,
                  onOpenDetail: onOpenDetail,
                  onOpenSeats: onOpenSeats,
                  onOpenBoarding: onOpenBoarding,
                  onEditDate: onEditDate,
                  onTransition: onTransition,
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
  final AdminDeparture departure;
  final bool canManage;
  final ValueChanged<AdminDeparture> onOpenDetail;
  final ValueChanged<AdminDeparture> onOpenSeats;
  final ValueChanged<AdminDeparture> onOpenBoarding;
  final ValueChanged<AdminDeparture> onEditDate;
  final void Function(AdminDeparture departure, String action) onTransition;

  const _Actions({
    required this.departure,
    required this.canManage,
    required this.onOpenDetail,
    required this.onOpenSeats,
    required this.onOpenBoarding,
    required this.onEditDate,
    required this.onTransition,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          key: Key('admin-departure-detail-${departure.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(departure),
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          key: Key('admin-departure-seats-${departure.id}'),
          tooltip: 'Sièges',
          onPressed: () => onOpenSeats(departure),
          icon: const Icon(Icons.event_seat_outlined),
        ),
        IconButton(
          key: Key('admin-departure-boarding-${departure.id}'),
          tooltip: 'Embarquement',
          onPressed: () => onOpenBoarding(departure),
          icon: const Icon(Icons.qr_code_scanner),
        ),
        if (canManage) ...[
          if (departure.canReschedule)
            IconButton(
              key: Key('admin-departure-edit-${departure.id}'),
              tooltip: 'Déplacer la date/heure',
              onPressed: () => onEditDate(departure),
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
          if (departure.canGenerateSeats)
            IconButton(
              key: Key('admin-departure-generate-seats-${departure.id}'),
              tooltip: 'Générer les sièges',
              onPressed: () => onTransition(departure, 'generate-seats'),
              icon: const Icon(Icons.grid_view_outlined),
            ),
          if (departure.canOpen)
            IconButton(
              key: Key('admin-departure-open-${departure.id}'),
              tooltip: 'Ouvrir',
              onPressed: () => onTransition(departure, 'open'),
              icon: const Icon(Icons.lock_open_outlined),
            ),
          if (departure.canClose)
            IconButton(
              key: Key('admin-departure-close-${departure.id}'),
              tooltip: 'Fermer',
              onPressed: () => onTransition(departure, 'close'),
              icon: const Icon(Icons.lock_outline),
            ),
          if (departure.canDepart)
            IconButton(
              key: Key('admin-departure-depart-${departure.id}'),
              tooltip: 'Marquer parti',
              onPressed: () => onTransition(departure, 'depart'),
              icon: const Icon(Icons.directions_bus_filled_outlined),
            ),
          if (departure.canCancel)
            IconButton(
              key: Key('admin-departure-cancel-${departure.id}'),
              tooltip: 'Annuler',
              onPressed: () => onTransition(departure, 'cancel'),
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFB42318)),
            ),
        ],
      ],
    );
  }
}
