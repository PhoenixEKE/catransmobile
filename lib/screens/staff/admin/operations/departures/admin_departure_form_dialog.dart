import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';

class AdminDepartureFormResult {
  final AdminDepartureCreateRequest? createRequest;
  final AdminDepartureDateUpdateRequest? updateRequest;

  const AdminDepartureFormResult({this.createRequest, this.updateRequest});
}

Future<AdminDepartureFormResult?> showAdminDepartureFormDialog({
  required BuildContext context,
  required bool isSubmitting,
  required List<AdminOperationRecord> templates,
  StructuredApiError? error,
  AdminDeparture? initialDeparture,
}) {
  return showDialog<AdminDepartureFormResult>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => _AdminDepartureFormDialog(
      isSubmitting: isSubmitting,
      templates: templates,
      error: error,
      initialDeparture: initialDeparture,
    ),
  );
}

class _AdminDepartureFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final List<AdminOperationRecord> templates;
  final StructuredApiError? error;
  final AdminDeparture? initialDeparture;

  const _AdminDepartureFormDialog({
    required this.isSubmitting,
    required this.templates,
    this.error,
    this.initialDeparture,
  });

  @override
  State<_AdminDepartureFormDialog> createState() =>
      _AdminDepartureFormDialogState();
}

class _AdminDepartureFormDialogState extends State<_AdminDepartureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  String? _templateId;

  bool get _isEdit => widget.initialDeparture != null;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: widget.initialDeparture?.departureDate ?? '',
    );
    _timeController = TextEditingController(
      text: widget.initialDeparture?.departureTime ?? '',
    );
    _templateId = widget.initialDeparture?.departureTemplateId;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 0 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : 520,
          maxHeight: MediaQuery.sizeOf(context).height - (compact ? 0 : 48),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEdit ? 'Déplacer le départ' : 'Créer un départ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (!_isEdit)
                  DropdownButtonFormField<String>(
                    key: const Key('admin-departure-template-field'),
                    initialValue: _templateId,
                    decoration: const InputDecoration(labelText: 'Template'),
                    items: widget.templates
                        .map((template) => DropdownMenuItem(
                              value: template.id,
                              child: Text(_templateLabel(template)),
                            ))
                        .toList(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Le template est obligatoire.'
                        : null,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) => setState(() => _templateId = value),
                  ),
                if (!_isEdit) const SizedBox(height: 12),
                TextFormField(
                  key: const Key('admin-departure-date-field'),
                  controller: _dateController,
                  decoration:
                      const InputDecoration(labelText: 'Date YYYY-MM-DD'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'La date est obligatoire.';
                    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
                      return 'Format attendu : YYYY-MM-DD.';
                    }
                    return null;
                  },
                  enabled: !widget.isSubmitting,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('admin-departure-time-field'),
                    controller: _timeController,
                    decoration:
                        const InputDecoration(labelText: 'Heure HH:MM'),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return "L'heure est obligatoire.";
                      if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
                        return 'Format attendu : HH:MM.';
                      }
                      return null;
                    },
                    enabled: !widget.isSubmitting,
                  ),
                ],
                if (widget.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.error!.userMessage,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const Key('admin-departure-form-submit'),
                      onPressed: widget.isSubmitting ? null : _submit,
                      child: Text(_isEdit ? 'Déplacer' : 'Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final date = _dateController.text.trim();
    if (_isEdit) {
      Navigator.pop(
        context,
        AdminDepartureFormResult(
          updateRequest: AdminDepartureDateUpdateRequest(
            departureDate: date,
            departureTime: _timeController.text.trim(),
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      AdminDepartureFormResult(
        createRequest: AdminDepartureCreateRequest(
          departureTemplateId: _templateId!,
          departureDate: date,
        ),
      ),
    );
  }

  String _templateLabel(AdminOperationRecord template) {
    final raw = template.raw;
    final station = raw['station'];
    final serviceClass = raw['service_class'];
    final stationName = station is Map ? station['name']?.toString() : null;
    final className =
        serviceClass is Map ? serviceClass['name']?.toString() : null;
    final time = raw['departure_time']?.toString();
    return [stationName, className, time]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' · ');
  }
}
