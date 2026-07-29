import 'package:flutter/material.dart';

class AdminServiceClassesToolbar extends StatefulWidget {
  final String initialQuery;
  final bool? selectedIsActive;
  final bool? selectedAllowsSeatSelection;
  final String? ordering;
  final bool canManage;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<bool?> onSeatSelectionChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const AdminServiceClassesToolbar({
    super.key,
    required this.initialQuery,
    required this.selectedIsActive,
    required this.selectedAllowsSeatSelection,
    required this.ordering,
    required this.canManage,
    required this.onSearch,
    required this.onActiveChanged,
    required this.onSeatSelectionChanged,
    required this.onOrderingChanged,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  State<AdminServiceClassesToolbar> createState() => _AdminServiceClassesToolbarState();
}

class _AdminServiceClassesToolbarState extends State<AdminServiceClassesToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant AdminServiceClassesToolbar oldWidget) {
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
        final compact = constraints.maxWidth < 820;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: compact ? double.infinity : 260,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: widget.onSearch,
                    decoration: InputDecoration(
                      labelText: 'Recherche',
                      hintText: 'Code ou nom',
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
                _Dropdown<bool>(
                  width: compact ? double.infinity : 150,
                  label: 'Statut',
                  value: widget.selectedIsActive,
                  onChanged: widget.onActiveChanged,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    DropdownMenuItem(value: true, child: Text('Actives')),
                    DropdownMenuItem(value: false, child: Text('Inactives')),
                  ],
                ),
                _Dropdown<bool>(
                  width: compact ? double.infinity : 210,
                  label: 'Sélection siège',
                  value: widget.selectedAllowsSeatSelection,
                  onChanged: widget.onSeatSelectionChanged,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Toutes')),
                    DropdownMenuItem(value: true, child: Text('Autorisée')),
                    DropdownMenuItem(value: false, child: Text('Automatique')),
                  ],
                ),
                _Dropdown<String>(
                  width: compact ? double.infinity : 220,
                  label: 'Tri',
                  value: widget.ordering,
                  onChanged: widget.onOrderingChanged,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Par défaut')),
                    DropdownMenuItem(value: 'name', child: Text('Nom A-Z')),
                    DropdownMenuItem(value: 'code', child: Text('Code A-Z')),
                    DropdownMenuItem(
                      value: '-default_loyalty_points',
                      child: Text('Points décroissants'),
                    ),
                    DropdownMenuItem(
                      value: '-created_at',
                      child: Text('Création récente'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir'),
                ),
                if (widget.canManage)
                  ElevatedButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.airline_seat_recline_extra),
                    label: const Text('Nouvelle classe'),
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
  final double width;
  final String label;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<DropdownMenuItem<T?>> items;

  const _Dropdown({
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
