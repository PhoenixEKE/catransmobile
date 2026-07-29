import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_fare_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminFareFormResult {
  final AdminFareCreateRequest? createRequest;
  const AdminFareFormResult.create(this.createRequest);
}

Future<AdminFareFormResult?> showAdminFareFormDialog(
    {required BuildContext context,
    required bool isSubmitting,
    required List<AdminRoute> routes,
    required List<AdminServiceClass> serviceClasses,
    StructuredApiError? error,
    AdminFareCreateRequest? initialCreateRequest}) {
  return showDialog<AdminFareFormResult>(
      context: context,
      useSafeArea: true,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final content = AdminFareFormDialog(
            isSubmitting: isSubmitting,
            routes: routes,
            serviceClasses: serviceClasses,
            error: error,
            initialCreateRequest: initialCreateRequest);
        if (size.width < 640) {
          return Dialog.fullscreen(child: SafeArea(child: content));
        }
        return Dialog(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
                width: size.width > 700 ? 640 : size.width - 32,
                height: size.height > 620 ? 560 : size.height * 0.9,
                child: content));
      });
}

class AdminFareFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final List<AdminRoute> routes;
  final List<AdminServiceClass> serviceClasses;
  final StructuredApiError? error;
  final AdminFareCreateRequest? initialCreateRequest;
  const AdminFareFormDialog(
      {super.key,
      required this.isSubmitting,
      required this.routes,
      required this.serviceClasses,
      this.error,
      this.initialCreateRequest});
  @override
  State<AdminFareFormDialog> createState() => _AdminFareFormDialogState();
}

class _AdminFareFormDialogState extends State<AdminFareFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _routeId;
  String? _serviceClassId;
  static const _currency = 'XOF';

  @override
  void initState() {
    super.initState();
    final draft = widget.initialCreateRequest;
    _routeId = draft?.routeId;
    _serviceClassId = draft?.serviceClassId;
    _amountController = TextEditingController(text: draft?.amount ?? '');
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
        _Header(
            title: 'Nouveau tarif',
            onClose: widget.isSubmitting ? null : () => Navigator.pop(context)),
        Expanded(
            child: Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(18), children: [
                  if (widget.error != null && widget.error?.field == null) ...[
                    StaffErrorState(message: widget.error!.userMessage),
                    const SizedBox(height: 12)
                  ],
                  _SelectField(
                      label: 'Route',
                      fieldName: 'route_id',
                      value: _routeId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      requiredField: true,
                      items: widget.routes
                          .map((r) => DropdownMenuItem(
                              value: r.id, child: Text(r.displayLabel)))
                          .toList(),
                      onChanged: (value) => setState(() => _routeId = value)),
                  const SizedBox(height: 12),
                  _SelectField(
                      label: 'Classe de service',
                      fieldName: 'service_class_id',
                      value: _serviceClassId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      requiredField: true,
                      items: widget.serviceClasses
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _serviceClassId = value)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _amountController,
                      enabled: !widget.isSubmitting,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: 'Montant *',
                          suffixText: _currency,
                          border: const OutlineInputBorder(),
                          errorText: widget.error?.field == 'amount'
                              ? widget.error!.userMessage
                              : null),
                      validator: _validateAmount),
                  const SizedBox(height: 8),
                  const Text('Devise : XOF',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
                  onPressed: widget.isSubmitting ? null : _submit,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: const Text('Créer'))
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
        AdminFareFormResult.create(AdminFareCreateRequest(
            routeId: _routeId!,
            serviceClassId: _serviceClassId!,
            amount: _amountController.text.replaceAll(',', '.'),
            currency: _currency)));
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  const _Header({required this.title, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(children: [
        const Icon(Icons.payments, color: Color(0xFF0F056B)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18))),
        IconButton(
            tooltip: 'Fermer',
            onPressed: onClose,
            icon: const Icon(Icons.close))
      ]));
}

class _SelectField extends StatelessWidget {
  final String label;
  final String fieldName;
  final String? value;
  final StructuredApiError? error;
  final bool enabled;
  final bool requiredField;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?> onChanged;
  const _SelectField(
      {required this.label,
      required this.fieldName,
      required this.value,
      required this.error,
      required this.enabled,
      required this.items,
      required this.onChanged,
      this.requiredField = false});
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          border: const OutlineInputBorder(),
          errorText: error?.field == fieldName ? error!.userMessage : null),
      validator: requiredField
          ? (value) =>
              value == null || value.isEmpty ? '$label est obligatoire.' : null
          : null);
}
