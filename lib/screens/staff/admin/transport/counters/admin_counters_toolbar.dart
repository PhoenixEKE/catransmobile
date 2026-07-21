import 'package:flutter/material.dart';

class AdminCountersToolbar extends StatefulWidget {
  final String initialQuery;
  final bool? selectedIsActive;
  final String? ordering;
  final bool canManage;
  final bool hasSelectedStation;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<String?> onOrderingChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const AdminCountersToolbar({super.key, required this.initialQuery, required this.selectedIsActive, required this.ordering, required this.canManage, required this.hasSelectedStation, required this.onSearch, required this.onActiveChanged, required this.onOrderingChanged, required this.onRefresh, required this.onCreate});

  @override
  State<AdminCountersToolbar> createState() => _AdminCountersToolbarState();
}

class _AdminCountersToolbarState extends State<AdminCountersToolbar> {
  late final TextEditingController _searchController;
  @override
  void initState() { super.initState(); _searchController = TextEditingController(text: widget.initialQuery); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) { final compact = constraints.maxWidth < 760; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Wrap(spacing: 10, runSpacing: 10, children: [
      SizedBox(width: compact ? double.infinity : 280, child: TextField(controller: _searchController, textInputAction: TextInputAction.search, onSubmitted: widget.onSearch, decoration: InputDecoration(labelText: 'Recherche', hintText: 'Code ou libellé', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(tooltip: 'Rechercher', onPressed: () => widget.onSearch(_searchController.text), icon: const Icon(Icons.arrow_forward)), border: const OutlineInputBorder(), isDense: true))),
      _Dropdown<bool>(width: compact ? double.infinity : 150, label: 'Statut', value: widget.selectedIsActive, onChanged: widget.onActiveChanged, items: const [DropdownMenuItem(value: null, child: Text('Tous')), DropdownMenuItem(value: true, child: Text('Actifs')), DropdownMenuItem(value: false, child: Text('Inactifs'))]),
      _Dropdown<String>(width: compact ? double.infinity : 190, label: 'Tri', value: widget.ordering, onChanged: widget.onOrderingChanged, items: const [DropdownMenuItem(value: null, child: Text('Par défaut')), DropdownMenuItem(value: 'code', child: Text('Code A-Z')), DropdownMenuItem(value: 'label', child: Text('Libellé A-Z')), DropdownMenuItem(value: '-created_at', child: Text('Création récente'))]),
    ]),
    const SizedBox(height: 12),
    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [OutlinedButton.icon(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh), label: const Text('Rafraîchir')), if (widget.canManage) ElevatedButton.icon(key: const Key('admin-counter-create'), onPressed: widget.hasSelectedStation ? widget.onCreate : null, icon: const Icon(Icons.add), label: const Text('Nouveau guichet'))]),
  ]); });
}

class _Dropdown<T> extends StatelessWidget { final double width; final String label; final T? value; final ValueChanged<T?>? onChanged; final List<DropdownMenuItem<T?>> items; const _Dropdown({required this.width, required this.label, required this.value, required this.onChanged, required this.items}); @override Widget build(BuildContext context) => SizedBox(width: width, child: DropdownButtonFormField<T?>(initialValue: value, items: items, onChanged: onChanged, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true))); }
