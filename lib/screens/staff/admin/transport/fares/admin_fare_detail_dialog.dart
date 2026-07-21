import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';

Future<void> showAdminFareDetailDialog(
    {required BuildContext context,
    required AdminFare fare,
    required Future<AdminFare> Function(String id) loadDetail}) async {
  final detail = await loadDetail(fare.id);
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              key: Key('admin-fare-details-${detail.id}'),
              title: const Text('Détail tarif',
                  key: Key('admin-fare-detail-title')),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    _Line('Route', detail.route.displayLabel),
                    _Line('Classe', detail.serviceClass.name),
                    _Line('Montant', detail.displayAmount),
                    _Line('Statut', detail.isActive ? 'Actif' : 'Inactif'),
                    _Line('Créé le', detail.createdAt),
                    _Line('Mis à jour', detail.updatedAt)
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Fermer'))
              ]));
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  const _Line(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label : ${value.trim().isEmpty ? '-' : value}'));
}
