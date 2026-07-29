import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';

class AdminCounterStationSelector extends StatelessWidget {
  final List<AdminStation> stations;
  final AdminStation? selectedStation;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const AdminCounterStationSelector({super.key, required this.stations, required this.selectedStation, required this.isLoading, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE4E7EF))),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: compact ? double.infinity : 260, child: Text('Gare des guichets', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
          SizedBox(
            width: compact ? double.infinity : 360,
            child: DropdownButtonFormField<String?>(
              key: const Key('admin-counter-station-selector'),
              initialValue: selectedStation?.id,
              items: stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: isLoading ? null : onChanged,
              isExpanded: true,
              decoration: InputDecoration(labelText: isLoading ? 'Chargement des gares...' : 'Sélectionner une gare', border: const OutlineInputBorder(), isDense: true),
            ),
          ),
          if (selectedStation != null) Text('Contexte : ${selectedStation!.name}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F056B))),
        ]);
      }),
    );
  }
}
