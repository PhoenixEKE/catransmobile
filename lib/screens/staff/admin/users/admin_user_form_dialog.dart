import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminUserFormResult {
  final AdminInternalUserCreateRequest? createRequest;
  final AdminInternalUserUpdateRequest? updateRequest;

  const AdminUserFormResult.create(this.createRequest) : updateRequest = null;
  const AdminUserFormResult.update(this.updateRequest) : createRequest = null;
}

Future<AdminUserFormResult?> showAdminUserFormDialog({
  required BuildContext context,
  required List<AdminInternalRoleOption> roles,
  required List<StaffStationRef> stations,
  required Future<List<StaffCounterRef>> Function(String? stationId)
      loadCountersForStation,
  required bool isSubmitting,
  StructuredApiError? error,
  AdminInternalUserDetail? initialUser,
  AdminInternalUserCreateRequest? initialCreateRequest,
  AdminInternalUserUpdateRequest? initialUpdateRequest,
}) {
  return showDialog<AdminUserFormResult>(
    context: context,
    useSafeArea: true,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = AdminUserFormDialog(
        roles: roles,
        stations: stations,
        loadCountersForStation: loadCountersForStation,
        isSubmitting: isSubmitting,
        error: error,
        initialUser: initialUser,
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
          width: size.width > 720 ? 680 : size.width - 32,
          height: size.height > 780 ? 720 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class AdminUserFormDialog extends StatefulWidget {
  final List<AdminInternalRoleOption> roles;
  final List<StaffStationRef> stations;
  final Future<List<StaffCounterRef>> Function(String? stationId)
      loadCountersForStation;
  final bool isSubmitting;
  final StructuredApiError? error;
  final AdminInternalUserDetail? initialUser;
  final AdminInternalUserCreateRequest? initialCreateRequest;
  final AdminInternalUserUpdateRequest? initialUpdateRequest;

  const AdminUserFormDialog({
    super.key,
    required this.roles,
    required this.stations,
    required this.loadCountersForStation,
    required this.isSubmitting,
    this.error,
    this.initialUser,
    this.initialCreateRequest,
    this.initialUpdateRequest,
  });

  @override
  State<AdminUserFormDialog> createState() => _AdminUserFormDialogState();
}

class _AdminUserFormDialogState extends State<AdminUserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _lastnameController;
  late final TextEditingController _firstnameController;
  late final TextEditingController _passwordController;
  List<StaffCounterRef> _counters = const [];
  String? _role;
  String? _stationId;
  String? _counterId;
  bool _isLoadingCounters = false;

  bool get _isEdit => widget.initialUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    final createDraft = widget.initialCreateRequest;
    final updateDraft = widget.initialUpdateRequest;
    _emailController = TextEditingController(
      text: updateDraft?.email ?? user?.email ?? createDraft?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: updateDraft?.phoneNumber ??
          user?.phoneNumber ??
          createDraft?.phoneNumber ??
          '',
    );
    _lastnameController = TextEditingController(
      text: updateDraft?.lastname ??
          user?.lastname ??
          createDraft?.lastname ??
          '',
    );
    _firstnameController = TextEditingController(
      text: updateDraft?.firstname ??
          user?.firstname ??
          createDraft?.firstname ??
          '',
    );
    _passwordController =
        TextEditingController(text: createDraft?.password ?? '');
    _role = updateDraft?.role ?? user?.role ?? createDraft?.role;
    _stationId = updateDraft != null
        ? updateDraft.stationId
        : user?.station?.id ?? createDraft?.stationId;
    _counterId = updateDraft != null
        ? updateDraft.counterId
        : user?.counter?.id ?? createDraft?.counterId;
    if (_stationId != null) _loadCounters(_stationId, keepCounter: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _lastnameController.dispose();
    _firstnameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRole = _selectedRole;
    final allowsStation = selectedRole?.allowsStation ?? true;
    final allowsCounter = selectedRole?.allowsCounter ?? false;
    final requiresStation = selectedRole?.requiresStation ?? false;
    final requiresCounter = selectedRole?.requiresCounter ?? false;

    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(
            title: _isEdit ? 'Modifier l’utilisateur' : 'Nouvel utilisateur',
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
                    controller: _firstnameController,
                    label: 'Prénom',
                    fieldName: 'firstname',
                    error: widget.error,
                    requiredField: true,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _lastnameController,
                    label: 'Nom',
                    fieldName: 'lastname',
                    error: widget.error,
                    requiredField: true,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _emailController,
                    label: 'Email',
                    fieldName: 'email',
                    error: widget.error,
                    requiredField: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _TextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    fieldName: 'phone_number',
                    error: widget.error,
                    requiredField: true,
                    keyboardType: TextInputType.phone,
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _passwordController,
                      label: 'Mot de passe initial',
                      fieldName: 'password',
                      error: widget.error,
                      requiredField: true,
                      obscureText: true,
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: InputDecoration(
                      labelText: 'Rôle',
                      border: const OutlineInputBorder(),
                      errorText: _fieldError('role'),
                    ),
                    items: widget.roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role.value,
                            child: Text(
                                role.label.isEmpty ? role.value : role.label),
                          ),
                        )
                        .toList(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Le rôle est obligatoire.'
                        : null,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _role = value;
                              if (_selectedRole?.allowsStation == false) {
                                _stationId = null;
                                _counterId = null;
                                _counters = const [];
                              }
                              if (_selectedRole?.allowsCounter == false) {
                                _counterId = null;
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: allowsStation ? _stationId : null,
                    decoration: InputDecoration(
                      labelText: requiresStation ? 'Gare *' : 'Gare',
                      border: const OutlineInputBorder(),
                      errorText: _fieldError('station_id'),
                    ),
                    items: widget.stations
                        .map(
                          (station) => DropdownMenuItem(
                            value: station.id,
                            child: Text(station.label),
                          ),
                        )
                        .toList(),
                    validator: (value) {
                      if (requiresStation && (value == null || value.isEmpty)) {
                        return 'La gare est obligatoire pour ce rôle.';
                      }
                      return null;
                    },
                    onChanged: !allowsStation || widget.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _stationId = value;
                              _counterId = null;
                            });
                            _loadCounters(value);
                          },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: allowsCounter ? _counterId : null,
                    decoration: InputDecoration(
                      labelText: _isLoadingCounters
                          ? 'Chargement des guichets...'
                          : requiresCounter
                              ? 'Guichet *'
                              : 'Guichet',
                      border: const OutlineInputBorder(),
                      errorText: _fieldError('counter_id'),
                    ),
                    items: _counters
                        .map(
                          (counter) => DropdownMenuItem(
                            value: counter.id,
                            child: Text(counter.label),
                          ),
                        )
                        .toList(),
                    validator: (value) {
                      if (requiresCounter && (value == null || value.isEmpty)) {
                        return 'Le guichet est obligatoire pour ce rôle.';
                      }
                      return null;
                    },
                    onChanged: !allowsCounter ||
                            widget.isSubmitting ||
                            _stationId == null ||
                            _isLoadingCounters
                        ? null
                        : (value) => setState(() => _counterId = value),
                  ),
                ],
              ),
            ),
          ),
          _Footer(
            isSubmitting: widget.isSubmitting,
            primaryLabel: _isEdit ? 'Enregistrer' : 'Créer',
            onCancel: () => Navigator.pop(context),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  AdminInternalRoleOption? get _selectedRole {
    final role = _role;
    if (role == null) return null;
    for (final option in widget.roles) {
      if (option.value == role) return option;
    }
    return null;
  }

  Future<void> _loadCounters(String? stationId,
      {bool keepCounter = false}) async {
    if (stationId == null || stationId.isEmpty) {
      setState(() {
        _counters = const [];
        _counterId = null;
      });
      return;
    }

    setState(() => _isLoadingCounters = true);
    try {
      final counters = await widget.loadCountersForStation(stationId);
      if (!mounted) return;
      setState(() {
        _counters = counters;
        if (!keepCounter ||
            !counters.any((counter) => counter.id == _counterId)) {
          _counterId = null;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingCounters = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit) {
      Navigator.pop(
        context,
        AdminUserFormResult.update(
          AdminInternalUserUpdateRequest(
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            lastname: _lastnameController.text.trim(),
            firstname: _firstnameController.text.trim(),
            role: _role,
            stationId: _stationId,
            counterId: _counterId,
            clearStation: _stationId == null,
            clearCounter: _counterId == null,
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      AdminUserFormResult.create(
        AdminInternalUserCreateRequest(
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          lastname: _lastnameController.text.trim(),
          firstname: _firstnameController.text.trim(),
          role: _role ?? '',
          password: _passwordController.text,
          stationId: _stationId,
          counterId: _counterId,
        ),
      ),
    );
  }

  String? _fieldError(String field) {
    final error = widget.error;
    if (error == null || error.field != field) return null;
    return error.userMessage;
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String fieldName;
  final StructuredApiError? error;
  final bool requiredField;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.fieldName,
    required this.error,
    this.requiredField = false,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        border: const OutlineInputBorder(),
        errorText: error?.field == fieldName ? error?.userMessage : null,
      ),
      validator: (value) {
        if (!requiredField) {
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return '$label est obligatoire.';
        }
        return null;
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.manage_accounts, color: Color(0xFF0F056B)),
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

class _Footer extends StatelessWidget {
  final bool isSubmitting;
  final String primaryLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _Footer({
    required this.isSubmitting,
    required this.primaryLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isSubmitting ? null : onCancel,
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(isSubmitting ? 'Envoi...' : primaryLabel),
          ),
        ],
      ),
    );
  }
}
