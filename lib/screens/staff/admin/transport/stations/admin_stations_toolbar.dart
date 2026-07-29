import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';

class AdminStationsToolbar extends StatefulWidget {
  final String initialQuery;
  final String? selectedCompanyId;
  final String? selectedCityId;
  final bool? selectedIsActive;
  final String? ordering;
  final List<AdminCompany> companies;
  final List<AdminCity> cities;
  final bool canManage;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onCompanyChanged;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const AdminStationsToolbar({
    super.key,
    required this.initialQuery,
    required this.selectedCompanyId,
    required this.selectedCityId,
    required this.selectedIsActive,
    required this.ordering,
    required this.companies,
    required this.cities,
    required this.canManage,
    required this.onSearch,
    required this.onCompanyChanged,
    required this.onCityChanged,
    required this.onActiveChanged,
    required this.onOrderingChanged,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  State<AdminStationsToolbar> createState() => _AdminStationsToolbarState();
}

class _AdminStationsToolbarState extends State<AdminStationsToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant AdminStationsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery && _searchController.text != widget.initialQuery) {
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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 900;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
            width: compact ? double.infinity : 260,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
              decoration: InputDecoration(
                labelText: 'Recherche',
                hintText: 'Nom, code ou ville',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(tooltip: 'Rechercher', onPressed: () => widget.onSearch(_searchController.text), icon: const Icon(Icons.arrow_forward)),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          _Dropdown<String>(
            width: compact ? double.infinity : 220,
            label: 'Compagnie',
            value: widget.selectedCompanyId,
            onChanged: widget.onCompanyChanged,
            items: [const DropdownMenuItem(value: null, child: Text('Toutes')), ...widget.companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
          ),
          _Dropdown<String>(
            width: compact ? double.infinity : 210,
            label: 'Ville',
            value: widget.selectedCityId,
            onChanged: widget.onCityChanged,
            items: [const DropdownMenuItem(value: null, child: Text('Toutes')), ...widget.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))],
          ),
          _Dropdown<bool>(
            width: compact ? double.infinity : 150,
            label: 'Statut',
            value: widget.selectedIsActive,
            onChanged: widget.onActiveChanged,
            items: const [DropdownMenuItem(value: null, child: Text('Tous')), DropdownMenuItem(value: true, child: Text('Actives')), DropdownMenuItem(value: false, child: Text('Inactives'))],
          ),
          _Dropdown<String>(
            width: compact ? double.infinity : 190,
            label: 'Tri',
            value: widget.ordering,
            onChanged: widget.onOrderingChanged,
            items: const [DropdownMenuItem(value: null, child: Text('Par défaut')), DropdownMenuItem(value: 'name', child: Text('Nom A-Z')), DropdownMenuItem(value: 'code', child: Text('Code A-Z')), DropdownMenuItem(value: '-created_at', child: Text('Création récente'))],
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
          OutlinedButton.icon(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh), label: const Text('Rafraîchir')),
          if (widget.canManage) ElevatedButton.icon(key: const Key('admin-station-create'), onPressed: widget.onCreate, icon: const Icon(Icons.add_business), label: const Text('Nouvelle gare')),
        ]),
      ]);
    });
  }
}

class _Dropdown<T> extends StatelessWidget {
  final double width;
  final String label;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _Dropdown({required this.width, required this.label, required this.value, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: DropdownButtonFormField<T?>(initialValue: value, items: items, onChanged: onChanged, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true)));
  }
}
