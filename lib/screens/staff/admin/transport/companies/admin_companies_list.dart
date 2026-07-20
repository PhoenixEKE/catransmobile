import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/screens/staff/admin/transport/shared/admin_transport_status_badge.dart';
import 'package:catrans_app/widgets/staff/staff_pagination_controls.dart';

class AdminCompaniesList extends StatelessWidget {
  final PagedResult<AdminCompany> page;
  final bool canManage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<AdminCompany> onOpenDetail;
  final ValueChanged<AdminCompany> onEdit;
  final ValueChanged<AdminCompany> onActivate;
  final ValueChanged<AdminCompany> onDeactivate;

  const AdminCompaniesList({
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
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Téléphone service client')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: page.results.map((company) {
            return DataRow(
              cells: [
                DataCell(Text(company.name.isEmpty ? '-' : company.name)),
                DataCell(Text(_nullable(company.code))),
                DataCell(Text(_nullable(company.customerServicePhone))),
                DataCell(AdminTransportStatusBadge(isActive: company.isActive)),
                DataCell(_Actions(
                  company: company,
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
      children: page.results.map((company) {
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
                          company.name.isEmpty ? 'Compagnie' : company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Code : ${_nullable(company.code)}',
                          style: const TextStyle(color: Color(0xFF656A78)),
                        ),
                      ],
                    ),
                  ),
                  AdminTransportStatusBadge(isActive: company.isActive),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Téléphone service client : ${_nullable(company.customerServicePhone)}',
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _Actions(
                  company: company,
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

  String _nullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '-';
    return trimmed;
  }
}

class _Actions extends StatelessWidget {
  final AdminCompany company;
  final bool canManage;
  final ValueChanged<AdminCompany> onOpenDetail;
  final ValueChanged<AdminCompany> onEdit;
  final ValueChanged<AdminCompany> onActivate;
  final ValueChanged<AdminCompany> onDeactivate;

  const _Actions({
    required this.company,
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
          key: Key('admin-company-detail-${company.id}'),
          tooltip: 'Détail',
          onPressed: () => onOpenDetail(company),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (canManage) ...[
          IconButton(
            key: Key('admin-company-edit-${company.id}'),
            tooltip: 'Modifier',
            onPressed: () => onEdit(company),
            icon: const Icon(Icons.edit_outlined),
          ),
          if (company.isActive)
            IconButton(
              key: Key('admin-company-deactivate-${company.id}'),
              tooltip: 'Désactiver',
              onPressed: () => onDeactivate(company),
              icon: const Icon(Icons.block, color: Color(0xFFB42318)),
            )
          else
            IconButton(
              key: Key('admin-company-activate-${company.id}'),
              tooltip: 'Activer',
              onPressed: () => onActivate(company),
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
