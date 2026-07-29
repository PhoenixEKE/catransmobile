import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminServiceClassFormResult {
  final AdminServiceClassCreateRequest? createRequest;
  final AdminServiceClassUpdateRequest? updateRequest;

  const AdminServiceClassFormResult.create(this.createRequest) : updateRequest = null;

  const AdminServiceClassFormResult.update(this.updateRequest) : createRequest = null;
}

Future<AdminServiceClassFormResult?> showAdminServiceClassFormDialog({
  required BuildContext context,
  required bool isSubmitting,
  StructuredApiError? error,
  AdminServiceClass? initialServiceClass,
  AdminServiceClassCreateRequest? initialCreateRequest,
  AdminServiceClassUpdateRequest? initialUpdateRequest,
}) {
  return showDialog<AdminServiceClassFormResult>(
    context: context,
    useSafeArea: true,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminServiceClassFormDialog(
        isSubmitting: isSubmitting,
        error: error,
        initialServiceClass: initialServiceClass,
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
          width: size.width > 660 ? 620 : size.width - 32,
          height: size.height > 660 ? 600 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminServiceClassFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final StructuredApiError? error;
  final AdminServiceClass? initialServiceClass;
  final AdminServiceClassCreateRequest? initialCreateRequest;
  final AdminServiceClassUpdateRequest? initialUpdateRequest;

  const AdminServiceClassFormDialog({
    super.key,
    required this.isSubmitting,
    this.error,
    this.initialServiceClass,
    this.initialCreateRequest,
    this.initialUpdateRequest,
  });

  @override
  State<AdminServiceClassFormDialog> createState() => _AdminServiceClassFormDialogState();
}

class _AdminServiceClassFormDialogState extends State<AdminServiceClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _pointsController;
  late final TextEditingController _rewardThresholdController;
  late bool _allowsSeatSelection;

  bool get _isEdit => widget.initialServiceClass != null;

  @override
  void initState() {
    super.initState();
    final serviceClass = widget.initialServiceClass;
    final createDraft = widget.initialCreateRequest;
    final updateDraft = widget.initialUpdateRequest;
    _codeController = TextEditingController(
      text: createDraft?.code ?? updateDraft?.code ?? serviceClass?.code ?? '',
    );
    _nameController = TextEditingController(
      text: createDraft?.name ?? updateDraft?.name ?? serviceClass?.name ?? '',
    );
    _pointsController = TextEditingController(
      text: (createDraft?.defaultLoyaltyPoints ??
              updateDraft?.defaultLoyaltyPoints ??
              serviceClass?.defaultLoyaltyPoints ??
              0)
          .toString(),
    );
    _rewardThresholdController = TextEditingController(
      text: (createDraft?.rewardThresholdPoints ??
              updateDraft?.rewardThresholdPoints ??
              serviceClass?.rewardThresholdPoints ??
              0)
          .toString(),
    );
    _allowsSeatSelection = createDraft?.allowsSeatSelection ??
        updateDraft?.allowsSeatSelection ??
        serviceClass?.allowsSeatSelection ??
        true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _pointsController.dispose();
    _rewardThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(
            title: _isEdit ? 'Modifier la classe' : 'Nouvelle classe',
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
                    controller: _codeController,
                    label: 'Code',
                    fieldName: 'code',
                    error: widget.error,
                    requiredField: true,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _nameController,
                    label: 'Nom',
                    fieldName: 'name',
                    error: widget.error,
                    requiredField: true,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _pointsController,
                    label: 'Points par ticket',
                    fieldName: 'default_loyalty_points',
                    error: widget.error,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _rewardThresholdController,
                    label: 'Seuil récompense',
                    fieldName: 'reward_threshold_points',
                    error: widget.error,
                    enabled: !widget.isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sélection manuelle du siège'),
                    subtitle: const Text('Autoriser le voyageur à choisir un siège.'),
                    value: _allowsSeatSelection,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) => setState(() => _allowsSeatSelection = value),
                  ),
                  if (widget.error?.field == 'allows_seat_selection')
                    Text(
                      widget.error!.userMessage,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
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
      Navigator.pop(context, AdminServiceClassFormResult.update(_buildUpdateRequest()));
      return;
    }
    Navigator.pop(
      context,
      AdminServiceClassFormResult.create(
        AdminServiceClassCreateRequest(
          code: _codeController.text,
          name: _nameController.text,
          defaultLoyaltyPoints: _readInt(_pointsController.text),
          rewardThresholdPoints: _readInt(_rewardThresholdController.text),
          allowsSeatSelection: _allowsSeatSelection,
        ),
      ),
    );
  }

  AdminServiceClassUpdateRequest _buildUpdateRequest() {
    final serviceClass = widget.initialServiceClass!;
    final points = _readInt(_pointsController.text);
    final rewardThreshold = _readInt(_rewardThresholdController.text);
    return AdminServiceClassUpdateRequest(
      code: _changedText(_codeController.text, serviceClass.code),
      name: _changedText(_nameController.text, serviceClass.name),
      defaultLoyaltyPoints:
          points == serviceClass.defaultLoyaltyPoints ? null : points,
      rewardThresholdPoints:
          rewardThreshold == serviceClass.rewardThresholdPoints ? null : rewardThreshold,
      allowsSeatSelection: _allowsSeatSelection == serviceClass.allowsSeatSelection
          ? null
          : _allowsSeatSelection,
    );
  }

  String? _changedText(String current, String? initial) {
    final trimmed = current.trim();
    if (trimmed == (initial ?? '').trim()) return null;
    return trimmed;
  }

  int _readInt(String value) => int.tryParse(value.trim()) ?? 0;
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
          const Icon(Icons.airline_seat_recline_extra, color: Color(0xFF0F056B)),
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

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String fieldName;
  final StructuredApiError? error;
  final bool enabled;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.fieldName,
    required this.error,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: _fieldError(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return null;
        if (int.tryParse(text) == null) return 'Valeur numérique invalide.';
        return null;
      },
    );
  }

  String? _fieldError() {
    if (error?.field == fieldName) return error!.userMessage;
    return null;
  }
}
