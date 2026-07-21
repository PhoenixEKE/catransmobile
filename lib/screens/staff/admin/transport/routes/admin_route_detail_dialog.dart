import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';

Future<void> showAdminRouteDetailDialog(
    {required BuildContext context,
    required AdminRoute route,
    required Future<AdminRoute> Function(String id) loadDetail}) async {
  final detail = await loadDetail(route.id);
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              key: Key('admin-route-details-${detail.id}'),
              title: const Text('Détail route',
                  key: Key('admin-route-detail-title')),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    _Line('Compagnie', detail.company.name),
                    _Line('Gare départ', detail.departureStation.name),
                    _Line(
                        'Ville départ',
                        detail.departureCity?.name ??
                            detail.departureStation.cityName),
                    _Line('Destination', detail.displayDestination),
                    _Line('Statut', detail.isActive ? 'Active' : 'Inactive'),
                    _Line('Créée le', detail.createdAt),
                    _Line('Mise à jour', detail.updatedAt)
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
