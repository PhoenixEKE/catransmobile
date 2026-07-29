import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';

Future<void> showAdminDepartureSeatDetailDialog({
  required BuildContext context,
  required AdminDepartureSeat seat,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Siège ${seat.displayLabel}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statut : ${seat.status}'),
          Text('Type : ${seat.seatType}'),
          Text('Ligne : ${seat.visual.rowNumber}'),
          Text('Colonne : ${seat.visual.columnNumber}'),
          if (seat.blocked.blockedReason.isNotEmpty)
            Text('Motif blocage : ${seat.blocked.blockedReason}'),
          if (seat.activeHoldPresent) const Text('Hold actif présent'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
