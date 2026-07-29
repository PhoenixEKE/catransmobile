import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminCityFormResult {
  final AdminCityCreateRequest? createRequest;
  final AdminCityUpdateRequest? updateRequest;

  const AdminCityFormResult.create(this.createRequest) : updateRequest = null;

  const AdminCityFormResult.update(this.updateRequest) : createRequest = null;
}

Future<AdminCityFormResult?> showAdminCityFormDialog({
  required BuildContext context,
  required bool isSubmitting,
  StructuredApiError? error,
  AdminCity? initialCity,
  AdminCityCreateRequest? initialCreateRequest,
  AdminCityUpdateRequest? initialUpdateRequest,
}) {
  return showDialog<AdminCityFormResult>(
    context: context,
    useSafeArea: true,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminCityFormDialog(
        isSubmitting: isSubmitting,
        error: error,
        initialCity: initialCity,
        initialCreateRequest: initialCreateRequest,
        initialUpdateRequest: initialUpdateRequest,
      );
      if (size.width < 640) {
        return Dialog.fullscreen(child: SafeArea(child: content));
      }
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: size.width > 620 ? 560 : size.width - 32,
          height: size.height > 520 ? 460 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminCityFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final StructuredApiError? error;
  final AdminCity? initialCity;
  final AdminCityCreateRequest? initialCreateRequest;
  final AdminCityUpdateRequest? initialUpdateRequest;

  const AdminCityFormDialog({
    super.key,
    required this.isSubmitting,
    this.error,
    this.initialCity,
    this.initialCreateRequest,
    this.initialUpdateRequest,
  });

  @override
  State<AdminCityFormDialog> createState() => _AdminCityFormDialogState();
}

class _AdminCityFormDialogState extends State<AdminCityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;

  bool get _isEdit => widget.initialCity != null;

  @override
  void initState() {
    super.initState();
    final city = widget.initialCity;
    final createDraft = widget.initialCreateRequest;
    final updateDraft = widget.initialUpdateRequest;
    _nameController = TextEditingController(
      text: createDraft?.name ?? updateDraft?.name ?? city?.name ?? '',
    );
    _countryController = TextEditingController(
      text: createDraft?.country ?? updateDraft?.country ?? city?.country ?? "Côte d'Ivoire",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(
            title: _isEdit ? 'Modifier la ville' : 'Nouvelle ville',
            onClose: widget.isSubmitting ? null : () => Navigator.pop(context),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (widget.error != null && widget.error?.field == null) ...[
                    StaffErrorState(message: widget.error!.userMessage),
                    const SizedBox(height: 12),
                  ],
                  _TextField(
                    controller: _nameController,
                    label: 'Nom',
                    fieldName: 'name',
                    error: widget.error,
                    requiredField: true,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _countryController,
                    label: 'Pays',
                    fieldName: 'country',
                    error: widget.error,
                    requiredField: true,
                    enabled: !widget.isSubmitting,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: widget.isSubmitting ? null : _submit,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isEdit ? Icons.save_outlined : Icons.add),
                  label: Text(_isEdit ? 'Enregistrer' : 'Créer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit) {
      Navigator.pop(context, AdminCityFormResult.update(_buildUpdateRequest()));
      return;
    }
    Navigator.pop(
      context,
      AdminCityFormResult.create(
        AdminCityCreateRequest(
          name: _nameController.text,
          country: _countryController.text,
        ),
      ),
    );
  }

  AdminCityUpdateRequest _buildUpdateRequest() {
    final city = widget.initialCity!;
    return AdminCityUpdateRequest(
      name: _changedText(_nameController.text, city.name),
      country: _changedText(_countryController.text, city.country),
    );
  }

  String? _changedText(String current, String? initial) {
    final trimmed = current.trim();
    if (trimmed == (initial ?? '').trim()) return null;
    return trimmed;
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.location_city, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String fieldName;
  final StructuredApiError? error;
  final bool requiredField;
  final bool enabled;

  const _TextField({
    required this.controller,
    required this.label,
    required this.fieldName,
    required this.error,
    this.requiredField = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        border: const OutlineInputBorder(),
        errorText: _fieldError(),
      ),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label est obligatoire.';
              }
              return null;
            }
          : null,
    );
  }

  String? _fieldError() {
    if (error?.field == fieldName) return error!.userMessage;
    return null;
  }
}
