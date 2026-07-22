import 'package:flutter/material.dart';

class AdminDeparturesToolbar extends StatefulWidget {
  final String? selectedStatus;
  final String? ordering;
  final String? dateFrom;
  final String? dateTo;
  final bool canManage;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onOrderingChanged;
  final void Function(String? from, String? to) onDateRangeChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onGenerate;

  const AdminDeparturesToolbar({
    super.key,
    required this.selectedStatus,
    required this.ordering,
    required this.dateFrom,
    required this.dateTo,
    required this.canManage,
    required this.onStatusChanged,
    required this.onOrderingChanged,
    required this.onDateRangeChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.onGenerate,
  });

  @override
  State<AdminDeparturesToolbar> createState() => _AdminDeparturesToolbarState();
}

class _AdminDeparturesToolbarState extends State<AdminDeparturesToolbar> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.dateFrom ?? '');
    _toController = TextEditingController(text: widget.dateTo ?? '');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 170,
          child: KeyedSubtree(
            key: ValueKey('admin-departures-status-${widget.selectedStatus}'),
            child: DropdownButtonFormField<String>(
              key: const Key('admin-departures-status-filter'),
              initialValue: widget.selectedStatus,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous')),
                DropdownMenuItem(value: 'scheduled', child: Text('Prévu')),
                DropdownMenuItem(value: 'open', child: Text('Ouvert')),
                DropdownMenuItem(value: 'closed', child: Text('Fermé')),
                DropdownMenuItem(value: 'departed', child: Text('Parti')),
                DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
              ],
              onChanged: widget.onStatusChanged,
            ),
          ),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            key: const Key('admin-departures-date-from'),
            controller: _fromController,
            decoration: const InputDecoration(labelText: 'Depuis'),
            onSubmitted: (_) => _applyDates(),
          ),
        ),
        SizedBox(
          width: 150,
          child: TextField(
            key: const Key('admin-departures-date-to'),
            controller: _toController,
            decoration: const InputDecoration(labelText: 'Jusqu’au'),
            onSubmitted: (_) => _applyDates(),
          ),
        ),
        SizedBox(
          width: 190,
          child: KeyedSubtree(
            key: ValueKey('admin-departures-ordering-${widget.ordering}'),
            child: DropdownButtonFormField<String>(
              key: const Key('admin-departures-ordering'),
              initialValue: widget.ordering,
              decoration: const InputDecoration(labelText: 'Tri'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Défaut')),
                DropdownMenuItem(
                    value: 'departure_date', child: Text('Date ↑')),
                DropdownMenuItem(
                    value: '-departure_date', child: Text('Date ↓')),
                DropdownMenuItem(value: 'status', child: Text('Statut ↑')),
                DropdownMenuItem(value: '-status', child: Text('Statut ↓')),
              ],
              onChanged: widget.onOrderingChanged,
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const Key('admin-departures-apply-dates'),
          onPressed: _applyDates,
          icon: const Icon(Icons.filter_alt_outlined),
          label: const Text('Filtrer'),
        ),
        OutlinedButton.icon(
          key: const Key('admin-departures-refresh'),
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Rafraîchir'),
        ),
        if (widget.canManage)
          ElevatedButton.icon(
            key: const Key('admin-departures-create'),
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Créer'),
          ),
        if (widget.canManage)
          OutlinedButton.icon(
            key: const Key('admin-departures-generate'),
            onPressed: widget.onGenerate,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Générer'),
          ),
      ],
    );
  }

  void _applyDates() {
    widget.onDateRangeChanged(_fromController.text, _toController.text);
  }
}
