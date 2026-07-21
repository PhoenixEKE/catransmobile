import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';

class AdminUsersToolbar extends StatefulWidget {
  final String initialQuery;
  final String? selectedRole;
  final String? selectedStationId;
  final String? selectedCounterId;
  final bool? selectedIsActive;
  final List<AdminInternalRoleOption> roles;
  final List<StaffStationRef> stations;
  final List<StaffCounterRef> counters;
  final bool isLoadingCounters;
  final bool canManage;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onStationChanged;
  final ValueChanged<String?> onCounterChanged;
  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onRefresh;
  final VoidCallback onResetFilters;
  final VoidCallback onCreate;

  const AdminUsersToolbar({
    super.key,
    required this.initialQuery,
    required this.selectedRole,
    required this.selectedStationId,
    required this.selectedCounterId,
    required this.selectedIsActive,
    required this.roles,
    required this.stations,
    required this.counters,
    required this.isLoadingCounters,
    required this.canManage,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onStationChanged,
    required this.onCounterChanged,
    required this.onActiveChanged,
    required this.onRefresh,
    required this.onResetFilters,
    required this.onCreate,
  });

  @override
  State<AdminUsersToolbar> createState() => _AdminUsersToolbarState();
}

class _AdminUsersToolbarState extends State<AdminUsersToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant AdminUsersToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        _searchController.text != widget.initialQuery) {
      _searchController.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final fields = [
          SizedBox(
            width: compact ? double.infinity : 280,
            child: TextField(
              key: const Key('admin-users-search-field'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
              onChanged: widget.onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Recherche',
                hintText: 'Nom, email ou téléphone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Rechercher',
                  onPressed: () => widget.onSearch(_searchController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          _Dropdown<String>(
            fieldKey: const Key('admin-users-role-filter'),
            width: compact ? double.infinity : 190,
            label: 'Rôle',
            value: widget.selectedRole,
            onChanged: widget.onRoleChanged,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Tous les rôles')),
              ...widget.roles.map(
                (role) => DropdownMenuItem(
                  value: role.value,
                  child: Text(role.label.isEmpty ? role.value : role.label),
                ),
              ),
            ],
          ),
          _Dropdown<String>(
            fieldKey: const Key('admin-users-station-filter'),
            width: compact ? double.infinity : 190,
            label: 'Gare',
            value: widget.selectedStationId,
            onChanged: widget.onStationChanged,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Toutes les gares')),
              ...widget.stations.map(
                (station) => DropdownMenuItem(
                  value: station.id,
                  child: Text(station.label),
                ),
              ),
            ],
          ),
          _Dropdown<String>(
            fieldKey: const Key('admin-users-counter-filter'),
            width: compact ? double.infinity : 190,
            label: widget.isLoadingCounters ? 'Guichets...' : 'Guichet',
            value: widget.selectedCounterId,
            onChanged: widget.selectedStationId == null
                ? null
                : widget.onCounterChanged,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Tous les guichets')),
              ...widget.counters.map(
                (counter) => DropdownMenuItem(
                  value: counter.id,
                  child: Text(counter.label),
                ),
              ),
            ],
          ),
          _Dropdown<bool>(
            fieldKey: const Key('admin-users-status-filter'),
            width: compact ? double.infinity : 150,
            label: 'Statut',
            value: widget.selectedIsActive,
            onChanged: widget.onActiveChanged,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: true, child: Text('Actifs')),
              DropdownMenuItem(value: false, child: Text('Inactifs')),
            ],
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: fields,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const Key('admin-users-reset-filters-button'),
                  onPressed: widget.onResetFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Réinitialiser filtres'),
                ),
                OutlinedButton.icon(
                  key: const Key('admin-users-refresh-button'),
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir'),
                ),
                if (widget.canManage)
                  ElevatedButton.icon(
                    key: const Key('admin-users-create-button'),
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ajouter un utilisateur'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final Key fieldKey;
  final double width;
  final String label;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _Dropdown({
    required this.fieldKey,
    required this.width,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        key: fieldKey,
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
