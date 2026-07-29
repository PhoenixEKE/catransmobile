import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/screens/staff/admin/operations/admin_departure_status_badge.dart';

Future<void> showAdminDepartureDetailDialog({
  required BuildContext context,
  required AdminDeparture departure,
  required Future<AdminDeparture> Function(String id) loadDetail,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminDepartureDetailDialog(
      departure: departure,
      loadDetail: loadDetail,
    ),
  );
}

class _AdminDepartureDetailDialog extends StatelessWidget {
  final AdminDeparture departure;
  final Future<AdminDeparture> Function(String id) loadDetail;

  const _AdminDepartureDetailDialog({
    required this.departure,
    required this.loadDetail,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 0 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : 620,
          maxHeight: MediaQuery.sizeOf(context).height - (compact ? 0 : 48),
        ),
        child: FutureBuilder<AdminDeparture>(
          future: loadDetail(departure.id),
          builder: (context, snapshot) {
            final detail = snapshot.data ?? departure;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Détail du départ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      AdminDepartureStatusBadge(
                        code: detail.status.code,
                        label: detail.status.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(minHeight: 2),
                  _Line(label: 'Identifiant', value: detail.id),
                  _Line(label: 'Date et heure', value: detail.displaySchedule),
                  _Line(label: 'Route', value: detail.displayRoute),
                  _Line(label: 'Gare', value: detail.displayStation),
                  _Line(label: 'Classe', value: detail.displayClass),
                  _Line(label: 'Template', value: detail.departureTemplateId),
                  _Line(label: 'Layout', value: detail.seatLayout?.name),
                  _Line(label: 'Ouvert le', value: detail.openedAt),
                  _Line(label: 'Fermé le', value: detail.closedAt),
                  _Line(label: 'Parti le', value: detail.departedAt),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String? value;

  const _Line({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayed = value == null || value!.trim().isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(displayed),
        ],
      ),
    );
  }
}
