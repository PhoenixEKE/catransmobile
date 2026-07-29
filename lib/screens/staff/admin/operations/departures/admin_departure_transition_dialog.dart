import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';

Future<bool?> showAdminDepartureTransitionDialog({
  required BuildContext context,
  required AdminDeparture departure,
  required String action,
  required bool isSubmitting,
}) {
  final label = _actionLabel(action);
  return showDialog<bool>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => AlertDialog(
      key: Key('admin-departure-$action-confirm-dialog'),
      title: Text('$label ce départ ?'),
      content: Text('${departure.displaySchedule}\n${departure.displayRoute}'),
      actions: [
        TextButton(
          onPressed:
              isSubmitting ? null : () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: Key('admin-departure-$action-confirm'),
          style: action == 'cancel'
              ? ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed:
              isSubmitting ? null : () => Navigator.pop(dialogContext, true),
          child: Text(label),
        ),
      ],
    ),
  );
}

String _actionLabel(String action) {
  switch (action) {
    case 'generate-seats':
      return 'Générer les sièges';
    case 'open':
      return 'Ouvrir';
    case 'close':
      return 'Fermer';
    case 'depart':
      return 'Marquer parti';
    case 'cancel':
      return 'Annuler';
    default:
      return 'Confirmer';
  }
}
