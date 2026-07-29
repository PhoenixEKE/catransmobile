import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminCompanyFormResult {
  final AdminCompanyCreateRequest? createRequest;
  final AdminCompanyUpdateRequest? updateRequest;

  const AdminCompanyFormResult.create(this.createRequest)
      : updateRequest = null;

  const AdminCompanyFormResult.update(this.updateRequest)
      : createRequest = null;
}

Future<AdminCompanyFormResult?> showAdminCompanyFormDialog({
  required BuildContext context,
  required bool isSubmitting,
  StructuredApiError? error,
  AdminCompany? initialCompany,
  AdminCompanyCreateRequest? initialCreateRequest,
  AdminCompanyUpdateRequest? initialUpdateRequest,
}) {
  return showDialog<AdminCompanyFormResult>(
    context: context,
    useSafeArea: true,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminCompanyFormDialog(
        isSubmitting: isSubmitting,
        error: error,
        initialCompany: initialCompany,
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
          width: size.width > 620 ? 580 : size.width - 32,
          height: size.height > 600 ? 520 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminCompanyFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final StructuredApiError? error;
  final AdminCompany? initialCompany;
  final AdminCompanyCreateRequest? initialCreateRequest;
  final AdminCompanyUpdateRequest? initialUpdateRequest;

  const AdminCompanyFormDialog({
    super.key,
    required this.isSubmitting,
    this.error,
    this.initialCompany,
    this.initialCreateRequest,
    this.initialUpdateRequest,
  });

  @override
  State<AdminCompanyFormDialog> createState() => _AdminCompanyFormDialogState();
}

class _AdminCompanyFormDialogState extends State<AdminCompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _phoneController;

  bool get _isEdit => widget.initialCompany != null;

  @override
  void initState() {
    super.initState();
    final company = widget.initialCompany;
    final createDraft = widget.initialCreateRequest;
    final updateDraft = widget.initialUpdateRequest;
    _nameController = TextEditingController(
      text: createDraft?.name ?? updateDraft?.name ?? company?.name ?? '',
    );
    _codeController = TextEditingController(
      text: createDraft?.code ??
          _draftPatchText(updateDraft?.code) ??
          company?.code ??
          '',
    );
    _phoneController = TextEditingController(
      text: createDraft?.customerServicePhone ??
          _draftPatchText(updateDraft?.customerServicePhone) ??
          company?.customerServicePhone ??
          '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(
            title: _isEdit ? 'Modifier la compagnie' : 'Nouvelle compagnie',
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
                    controller: _codeController,
                    label: 'Code',
                    fieldName: 'code',
                    error: widget.error,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _phoneController,
                    label: 'Téléphone service client',
                    fieldName: 'customer_service_phone',
                    error: widget.error,
                    enabled: !widget.isSubmitting,
                    keyboardType: TextInputType.phone,
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
                  onPressed:
                      widget.isSubmitting ? null : () => Navigator.pop(context),
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
      Navigator.pop(
        context,
        AdminCompanyFormResult.update(_buildUpdateRequest()),
      );
      return;
    }
    Navigator.pop(
      context,
      AdminCompanyFormResult.create(
        AdminCompanyCreateRequest(
          name: _nameController.text,
          code: _codeController.text,
          customerServicePhone: _phoneController.text,
        ),
      ),
    );
  }

  AdminCompanyUpdateRequest _buildUpdateRequest() {
    final company = widget.initialCompany!;
    return AdminCompanyUpdateRequest(
      name: _changedText(_nameController.text, company.name),
      code: _nullablePatch(_codeController.text, company.code),
      customerServicePhone:
          _nullablePatch(_phoneController.text, company.customerServicePhone),
    );
  }

  String? _changedText(String current, String? initial) {
    final trimmed = current.trim();
    if (trimmed == (initial ?? '').trim()) return null;
    return trimmed;
  }

  AdminTransportPatchField<String> _nullablePatch(
    String current,
    String? initial,
  ) {
    final trimmed = current.trim();
    final normalizedInitial = (initial ?? '').trim();
    if (trimmed == normalizedInitial) {
      return const AdminTransportPatchField.absent();
    }
    if (trimmed.isEmpty) return const AdminTransportPatchField.clear();
    return AdminTransportPatchField.value(trimmed);
  }

  String? _draftPatchText(AdminTransportPatchField<String>? field) {
    if (field == null || !field.isProvided) return null;
    return field.value ?? '';
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
          const Icon(Icons.business, color: Color(0xFF0F056B)),
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
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.fieldName,
    required this.error,
    this.requiredField = false,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
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
