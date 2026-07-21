import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';

class AdminFaresToolbar extends StatefulWidget {
  final String initialQuery;
  final String? selectedRouteId;
  final String? selectedServiceClassId;
  final String? selectedCurrency;
  final bool? selectedIsActive;
  final String? ordering;
  final List<AdminRoute> routes;
  final List<AdminServiceClass> serviceClasses;
  final bool canManage;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onRouteChanged;
  final ValueChanged<String?> onServiceClassChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const AdminFaresToolbar(
      {super.key,
      required this.initialQuery,
      required this.selectedRouteId,
      required this.selectedServiceClassId,
      required this.selectedCurrency,
      required this.selectedIsActive,
      required this.ordering,
      required this.routes,
      required this.serviceClasses,
      required this.canManage,
      required this.onSearch,
      required this.onRouteChanged,
      required this.onServiceClassChanged,
      required this.onCurrencyChanged,
      required this.onActiveChanged,
      required this.onOrderingChanged,
      required this.onRefresh,
      required this.onCreate});

  @override
  State<AdminFaresToolbar> createState() => _AdminFaresToolbarState();
}

class _AdminFaresToolbarState extends State<AdminFaresToolbar> {
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
                            hintText: 'Route, classe, devise',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                                tooltip: 'Rechercher',
                                onPressed: () =>
                                    widget.onSearch(_searchController.text),
                                icon: const Icon(Icons.arrow_forward)),
                            border: const OutlineInputBorder(),
                            isDense: true))),
                _Dropdown<String>(
                    width: compact ? double.infinity : 260,
                    label: 'Route',
                    value: widget.selectedRouteId,
                    onChanged: widget.onRouteChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.routes.map((r) => DropdownMenuItem(
                          value: r.id, child: Text(r.displayLabel)))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 190,
                    label: 'Classe',
                    value: widget.selectedServiceClassId,
                    onChanged: widget.onServiceClassChanged,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Toutes')),
                      ...widget.serviceClasses.map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 140,
                    label: 'Devise',
                    value: widget.selectedCurrency,
                    onChanged: widget.onCurrencyChanged,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Toutes')),
                      DropdownMenuItem(value: 'XOF', child: Text('XOF'))
                    ]),
                _Dropdown<bool>(
                    width: compact ? double.infinity : 150,
                    label: 'Statut',
                    value: widget.selectedIsActive,
                    onChanged: widget.onActiveChanged,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: true, child: Text('Actifs')),
                      DropdownMenuItem(value: false, child: Text('Inactifs'))
                    ]),
                _Dropdown<String>(
                    width: compact ? double.infinity : 190,
                    label: 'Tri',
                    value: widget.ordering,
                    onChanged: widget.onOrderingChanged,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Par défaut')),
                      DropdownMenuItem(
                          value: 'amount', child: Text('Montant croissant')),
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
                          key: const Key('admin-fare-create'),
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouveau tarif'))
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
