import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminCitiesList extends StatelessWidget {
  final PagedResult<AdminCity> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminCity> onOpenDetail;
  final ValueChanged<AdminCity> onEdit;
  final ValueChanged<AdminCity> onActivate;
  final ValueChanged<AdminCity> onDeactivate;

  const AdminCitiesList({
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
            if (useCards) _buildCards() else _buildTable(),
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
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Pays')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((city) {
            return DataRow(
              cells: [
                DataCell(Text(city.name.isEmpty ? '-' : city.name)),
                DataCell(Text(city.country.isEmpty ? '-' : city.country)),
                DataCell(AdminTransportStatusBadge(isActive: city.isActive)),
                DataCell(_Actions(
                  city: city,
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
      children: page.results.map((city) {
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
                      city.name.isEmpty ? 'Ville' : city.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  AdminTransportStatusBadge(isActive: city.isActive),
                ],
              ),
              const SizedBox(height: 10),
              Text('Pays : ${city.country.isEmpty ? '-' : city.country}'),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  city: city,
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
  final AdminCity city;
  final bool canManage;
  final ValueChanged<AdminCity> onOpenDetail;
  final ValueChanged<AdminCity> onEdit;
  final ValueChanged<AdminCity> onActivate;
  final ValueChanged<AdminCity> onDeactivate;

  const _Actions({
    required this.city,
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
          key: Key('admin-city-detail-${city.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(city),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            key: Key('admin-city-edit-${city.id}'),
            tooltip: 'Modifier',
            onPressed: () => onEdit(city),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (city.isActive)
            IconButton(
              key: Key('admin-city-deactivate-${city.id}'),
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(city),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              key: Key('admin-city-activate-${city.id}'),
              tooltip: 'Activer',
              onPressed: () => onActivate(city),
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
