import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

Future<AdminFareReplaceRequest?> showAdminFareReplaceDialog(
    {required BuildContext context,
    required bool isSubmitting,
    required AdminFare fare,
    StructuredApiError? error,
    AdminFareReplaceRequest? initialRequest}) {
  return showDialog<AdminFareReplaceRequest>(
      context: context,
      useSafeArea: true,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final content = AdminFareReplaceDialog(
            isSubmitting: isSubmitting,
            fare: fare,
            error: error,
            initialRequest: initialRequest);
        if (size.width < 640) {
          return Dialog.fullscreen(child: SafeArea(child: content));
        }
        return Dialog(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
                width: size.width > 660 ? 620 : size.width - 32,
                height: size.height > 600 ? 540 : size.height * 0.9,
                child: content));
      });
}

class AdminFareReplaceDialog extends StatefulWidget {
  final bool isSubmitting;
  final AdminFare fare;
  final StructuredApiError? error;
  final AdminFareReplaceRequest? initialRequest;
  const AdminFareReplaceDialog(
      {super.key,
      required this.isSubmitting,
      required this.fare,
      this.error,
      this.initialRequest});
  @override
  State<AdminFareReplaceDialog> createState() => _AdminFareReplaceDialogState();
}

class _AdminFareReplaceDialogState extends State<AdminFareReplaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.initialRequest?.amount ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFFF5F6FA),
      child: Column(children: [
        Container(
            key: const Key('admin-fare-replace-dialog'),
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Row(children: [
              const Icon(Icons.price_change_outlined, color: Color(0xFF0F056B)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Remplacer le tarif',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18))),
              IconButton(
                  tooltip: 'Fermer',
                  onPressed:
                      widget.isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close))
            ])),
        Expanded(
            child: Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(18), children: [
                  if (widget.error != null && widget.error?.field == null) ...[
                    StaffErrorState(message: widget.error!.userMessage),
                    const SizedBox(height: 12)
                  ],
                  Text('Route : ${widget.fare.route.displayLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Classe : ${widget.fare.serviceClass.name}'),
                  Text('Montant actuel : ${widget.fare.displayAmount}'),
                  const SizedBox(height: 14),
                  const Text(
                      "L'ancien tarif sera désactivé et conservé dans l'historique.",
                      style: TextStyle(color: Color(0xFF666A76))),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _amountController,
                      enabled: !widget.isSubmitting,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: 'Nouveau montant *',
                          suffixText: widget.fare.currency,
                          border: const OutlineInputBorder(),
                          errorText: widget.error?.field == 'amount'
                              ? widget.error!.userMessage
                              : null),
                      validator: _validateAmount),
                ]))),
        Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed:
                      widget.isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler')),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                  key: const Key('admin-fare-replace-confirm'),
                  onPressed: widget.isSubmitting ? null : _submit,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Remplacer'))
            ])),
      ]));

  String? _validateAmount(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) {
      return 'Montant obligatoire.';
    }
    final parsed = num.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Le montant doit être strictement positif.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
        context,
        AdminFareReplaceRequest(
            amount: _amountController.text.replaceAll(',', '.'),
            currency: widget.fare.currency));
  }
}
