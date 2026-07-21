import 'package:flutter/material.dart';

Future<bool?> showAdminBoardingConfirmationDialog({
  required BuildContext context,
  required String identifier,
  required bool isToken,
  required bool isSubmitting,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => AlertDialog(
      key: const Key('admin-boarding-confirmation-dialog'),
      title: const Text('Valider le billet ?'),
      content: Text(
        '${isToken ? 'Token QR' : 'Référence'} : $identifier',
      ),
      actions: [
        TextButton(
          onPressed:
              isSubmitting ? null : () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: const Key('admin-boarding-confirm'),
          onPressed:
              isSubmitting ? null : () => Navigator.pop(dialogContext, true),
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}
