import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminStationFormResult {
  final AdminStationCreateRequest? createRequest;
  final AdminStationUpdateRequest? updateRequest;
  const AdminStationFormResult.create(this.createRequest) : updateRequest = null;
  const AdminStationFormResult.update(this.updateRequest) : createRequest = null;
}

Future<AdminStationFormResult?> showAdminStationFormDialog({required BuildContext context, required bool isSubmitting, required List<AdminCompany> companies, required List<AdminCity> cities, StructuredApiError? error, AdminStation? initialStation, AdminStationCreateRequest? initialCreateRequest, AdminStationUpdateRequest? initialUpdateRequest}) {
  return showDialog<AdminStationFormResult>(context: context, useSafeArea: true, barrierDismissible: !isSubmitting, builder: (dialogContext) {
    final size = MediaQuery.sizeOf(dialogContext);
    final content = AdminStationFormDialog(isSubmitting: isSubmitting, companies: companies, cities: cities, error: error, initialStation: initialStation, initialCreateRequest: initialCreateRequest, initialUpdateRequest: initialUpdateRequest);
    if (size.width < 640) return Dialog.fullscreen(child: SafeArea(child: content));
    return Dialog(clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: SizedBox(width: size.width > 700 ? 660 : size.width - 32, height: size.height > 720 ? 660 : size.height * 0.9, child: content));
  });
}

class AdminStationFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final List<AdminCompany> companies;
  final List<AdminCity> cities;
  final StructuredApiError? error;
  final AdminStation? initialStation;
  final AdminStationCreateRequest? initialCreateRequest;
  final AdminStationUpdateRequest? initialUpdateRequest;
  const AdminStationFormDialog({super.key, required this.isSubmitting, required this.companies, required this.cities, this.error, this.initialStation, this.initialCreateRequest, this.initialUpdateRequest});
  @override
  State<AdminStationFormDialog> createState() => _AdminStationFormDialogState();
}

class _AdminStationFormDialogState extends State<AdminStationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _representativeController;
  String? _companyId;
  String? _cityId;
  bool get _isEdit => widget.initialStation != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initialStation;
    final c = widget.initialCreateRequest;
    final u = widget.initialUpdateRequest;
    _nameController = TextEditingController(text: c?.name ?? u?.name ?? s?.name ?? '');
    _codeController = TextEditingController(text: c?.code ?? _draftPatchText(u?.code) ?? s?.code ?? '');
    _phoneController = TextEditingController(text: c?.phoneLine ?? _draftPatchText(u?.phoneLine) ?? s?.phoneLine ?? '');
    _representativeController = TextEditingController(text: c?.representative ?? _draftPatchText(u?.representative) ?? s?.representative ?? '');
    _companyId = c?.companyId ?? u?.companyId ?? s?.company.id;
    _cityId = c?.cityId ?? _draftPatchText(u?.cityId) ?? s?.city?.id;
  }

  @override
  void dispose() { _nameController.dispose(); _codeController.dispose(); _phoneController.dispose(); _representativeController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(color: const Color(0xFFF5F6FA), child: Column(children: [
      _Header(title: _isEdit ? 'Modifier la gare' : 'Nouvelle gare', onClose: widget.isSubmitting ? null : () => Navigator.pop(context)),
      Expanded(child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
        if (widget.error != null && widget.error?.field == null) ...[StaffErrorState(message: widget.error!.userMessage), const SizedBox(height: 12)],
        _SelectField(label: 'Compagnie', fieldName: 'company_id', value: _companyId, error: widget.error, enabled: !widget.isSubmitting, items: widget.companies.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(), onChanged: (value) => setState(() => _companyId = value), requiredField: true),
        const SizedBox(height: 12),
        _SelectField(label: 'Ville', fieldName: 'city_id', value: _cityId, error: widget.error, enabled: !widget.isSubmitting, items: [const DropdownMenuItem(value: null, child: Text('Aucune ville')), ...widget.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (value) => setState(() => _cityId = value)),
        const SizedBox(height: 12),
        _TextField(controller: _nameController, label: 'Nom', fieldName: 'name', error: widget.error, requiredField: true, enabled: !widget.isSubmitting),
        const SizedBox(height: 12),
        _TextField(controller: _codeController, label: 'Code', fieldName: 'code', error: widget.error, enabled: !widget.isSubmitting),
        const SizedBox(height: 12),
        _TextField(controller: _phoneController, label: 'Téléphone', fieldName: 'phone_line', error: widget.error, enabled: !widget.isSubmitting, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _TextField(controller: _representativeController, label: 'Représentant', fieldName: 'representative', error: widget.error, enabled: !widget.isSubmitting),
      ]))),
      Container(padding: const EdgeInsets.all(16), color: Colors.white, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: widget.isSubmitting ? null : () => Navigator.pop(context), child: const Text('Annuler')), const SizedBox(width: 10), ElevatedButton.icon(onPressed: widget.isSubmitting ? null : _submit, icon: widget.isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isEdit ? Icons.save_outlined : Icons.add), label: Text(_isEdit ? 'Enregistrer' : 'Créer'))])),
    ]));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isEdit) { Navigator.pop(context, AdminStationFormResult.update(_buildUpdateRequest())); return; }
    Navigator.pop(context, AdminStationFormResult.create(AdminStationCreateRequest(name: _nameController.text, companyId: _companyId!, cityId: _cityId, code: _codeController.text, phoneLine: _phoneController.text, representative: _representativeController.text)));
  }

  AdminStationUpdateRequest _buildUpdateRequest() {
    final s = widget.initialStation!;
    return AdminStationUpdateRequest(name: _changedText(_nameController.text, s.name), companyId: _companyId == s.company.id ? null : _companyId, cityId: _nullablePatch(_cityId, s.city?.id), code: _nullablePatch(_codeController.text, s.code), phoneLine: _nullablePatch(_phoneController.text, s.phoneLine), representative: _nullablePatch(_representativeController.text, s.representative));
  }

  String? _changedText(String current, String? initial) { final trimmed = current.trim(); if (trimmed == (initial ?? '').trim()) return null; return trimmed; }
  AdminTransportPatchField<String> _nullablePatch(String? current, String? initial) { final trimmed = current?.trim() ?? ''; final normalizedInitial = (initial ?? '').trim(); if (trimmed == normalizedInitial) return const AdminTransportPatchField.absent(); if (trimmed.isEmpty) return const AdminTransportPatchField.clear(); return AdminTransportPatchField.value(trimmed); }
  String? _draftPatchText(AdminTransportPatchField<String>? field) { if (field == null || !field.isProvided) return null; return field.value ?? ''; }
}

class _Header extends StatelessWidget { final String title; final VoidCallback? onClose; const _Header({required this.title, required this.onClose}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), color: Colors.white, child: Row(children: [const Icon(Icons.store_mall_directory, color: Color(0xFF0F056B)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))), IconButton(tooltip: 'Fermer', onPressed: onClose, icon: const Icon(Icons.close))])); }

class _TextField extends StatelessWidget { final TextEditingController controller; final String label; final String fieldName; final StructuredApiError? error; final bool requiredField; final bool enabled; final TextInputType? keyboardType; const _TextField({required this.controller, required this.label, required this.fieldName, required this.error, this.requiredField = false, this.enabled = true, this.keyboardType}); @override Widget build(BuildContext context) => TextFormField(controller: controller, enabled: enabled, keyboardType: keyboardType, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: requiredField ? '$label *' : label, border: const OutlineInputBorder(), errorText: error?.field == fieldName ? error!.userMessage : null), validator: requiredField ? (value) => value == null || value.trim().isEmpty ? '$label est obligatoire.' : null : null); }

class _SelectField extends StatelessWidget { final String label; final String fieldName; final String? value; final StructuredApiError? error; final bool enabled; final bool requiredField; final List<DropdownMenuItem<String?>> items; final ValueChanged<String?> onChanged; const _SelectField({required this.label, required this.fieldName, required this.value, required this.error, required this.enabled, required this.items, required this.onChanged, this.requiredField = false}); @override Widget build(BuildContext context) => DropdownButtonFormField<String?>(initialValue: value, items: items, onChanged: enabled ? onChanged : null, isExpanded: true, decoration: InputDecoration(labelText: requiredField ? '$label *' : label, border: const OutlineInputBorder(), errorText: error?.field == fieldName ? error!.userMessage : null), validator: requiredField ? (value) => value == null || value.isEmpty ? '$label est obligatoire.' : null : null); }
