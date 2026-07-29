import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';

Future<String?> showAdminDepartureSeatActionDialog({
  required BuildContext context,
  required AdminDepartureSeat seat,
  required String action,
  required bool isSubmitting,
  StructuredApiError? error,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => _AdminDepartureSeatActionDialog(
      seat: seat,
      action: action,
      isSubmitting: isSubmitting,
      error: error,
    ),
  );
}

class _AdminDepartureSeatActionDialog extends StatefulWidget {
  final AdminDepartureSeat seat;
  final String action;
  final bool isSubmitting;
  final StructuredApiError? error;

  const _AdminDepartureSeatActionDialog({
    required this.seat,
    required this.action,
    required this.isSubmitting,
    this.error,
  });

  @override
  State<_AdminDepartureSeatActionDialog> createState() =>
      _AdminDepartureSeatActionDialogState();
}

class _AdminDepartureSeatActionDialogState
    extends State<_AdminDepartureSeatActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.action == 'block' ? 'Bloquer' : 'Débloquer';
    return AlertDialog(
      key: Key('admin-seat-${widget.action}-dialog'),
      title: Text('$label le siège ${widget.seat.displayLabel}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('admin-seat-action-reason-field'),
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motif'),
              maxLines: 3,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le motif est obligatoire.'
                  : null,
              enabled: !widget.isSubmitting,
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.error!.userMessage,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: Key('admin-seat-${widget.action}-confirm'),
          onPressed: widget.isSubmitting ? null : _submit,
          child: Text(label),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _reasonController.text.trim());
  }
}
