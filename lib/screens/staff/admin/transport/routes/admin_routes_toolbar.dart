import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';

class AdminRoutesToolbar extends StatefulWidget {
  final String initialQuery;
  final String? selectedCompanyId;
  final String? selectedDepartureStationId;
  final String? selectedDepartureCityId;
  final String? selectedDestinationCityId;
  final bool? selectedIsActive;
  final String? ordering;
  final List<AdminCompany> companies;
  final List<AdminStation> stations;
  final List<AdminCity> cities;
  final bool canManage;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onCompanyChanged;
  final ValueChanged<String?> onDepartureStationChanged;
  final ValueChanged<String?> onDepartureCityChanged;
  final ValueChanged<String?> onDestinationCityChanged;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const AdminRoutesToolbar(
      {super.key,
      required this.initialQuery,
      required this.selectedCompanyId,
      required this.selectedDepartureStationId,
      required this.selectedDepartureCityId,
      required this.selectedDestinationCityId,
      required this.selectedIsActive,
      required this.ordering,
      required this.companies,
      required this.stations,
      required this.cities,
      required this.canManage,
      required this.onSearch,
      required this.onCompanyChanged,
      required this.onDepartureStationChanged,
      required this.onDepartureCityChanged,
      required this.onDestinationCityChanged,
      required this.onActiveChanged,
      required this.onOrderingChanged,
      required this.onRefresh,
      required this.onCreate});

  @override
  State<AdminRoutesToolbar> createState() => _AdminRoutesToolbarState();
}

class _AdminRoutesToolbarState extends State<AdminRoutesToolbar> {
  late final TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: [
                SizedBox(
                    width: compact ? double.infinity : 260,
                    child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: widget.onSearch,
                        decoration: InputDecoration(
                            labelText: 'Recherche',
                            hintText: 'Gare, destination, compagnie',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                                tooltip: 'Rechercher',
                                onPressed: () =>
                                    widget.onSearch(_searchController.text),
                                icon: const Icon(Icons.arrow_forward)),
                            border: const OutlineInputBorder(),
                            isDense: true))),
                _Dropdown<String>(
                    width: compact ? double.infinity : 220,
                    label: 'Compagnie',
                    value: widget.selectedCompanyId,
                    onChanged: widget.onCompanyChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.companies.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 240,
                    label: 'Gare départ',
                    value: widget.selectedDepartureStationId,
                    onChanged: widget.onDepartureStationChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.stations.map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 190,
                    label: 'Ville départ',
                    value: widget.selectedDepartureCityId,
                    onChanged: widget.onDepartureCityChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.cities.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 190,
                    label: 'Ville arrivée',
                    value: widget.selectedDestinationCityId,
                    onChanged: widget.onDestinationCityChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.cities.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                    ]),
                _Dropdown<bool>(
                    width: compact ? double.infinity : 150,
                    label: 'Statut',
                    value: widget.selectedIsActive,
                    onChanged: widget.onActiveChanged,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: true, child: Text('Actives')),
                      DropdownMenuItem(value: false, child: Text('Inactives'))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 210,
                    label: 'Tri',
                    value: widget.ordering,
                    onChanged: widget.onOrderingChanged,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Par défaut')),
                      DropdownMenuItem(
                          value: 'destination_name_snapshot',
                          child: Text('Destination A-Z')),
                      DropdownMenuItem(
                          value: '-created_at',
                          child: Text('Création récente')),
                      DropdownMenuItem(
                          value: 'is_active', child: Text('Statut'))
                    ]),
              ]),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                        onPressed: widget.onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rafraîchir')),
                    if (widget.canManage)
                      ElevatedButton.icon(
                          key: const Key('admin-route-create'),
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle route'))
                  ]),
            ]);
      });
}

class _Dropdown<T> extends StatelessWidget {
  final double width;
  final String label;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<DropdownMenuItem<T?>> items;
  const _Dropdown(
      {required this.width,
      required this.label,
      required this.value,
      required this.onChanged,
      required this.items});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true)));
}
