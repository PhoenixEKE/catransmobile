import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminScheduleFormResult {
  final AdminScheduleCreateRequest? createRequest;
  final AdminScheduleUpdateRequest? updateRequest;

  const AdminScheduleFormResult.create(this.createRequest)
      : updateRequest = null;

  const AdminScheduleFormResult.update(this.updateRequest)
      : createRequest = null;
}

Future<AdminScheduleFormResult?> showAdminScheduleFormDialog({
  required BuildContext context,
  required bool isSubmitting,
  required List<AdminStation> stations,
  required List<AdminRoute> routes,
  required List<AdminServiceClass> serviceClasses,
  StructuredApiError? error,
  AdminSchedule? initialSchedule,
  AdminScheduleCreateRequest? initialCreateRequest,
  AdminScheduleUpdateRequest? initialUpdateRequest,
}) {
  return showDialog<AdminScheduleFormResult>(
      context: context,
      useSafeArea: true,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final content = AdminScheduleFormDialog(
            isSubmitting: isSubmitting,
            stations: stations,
            routes: routes,
            serviceClasses: serviceClasses,
            error: error,
            initialSchedule: initialSchedule,
            initialCreateRequest: initialCreateRequest,
            initialUpdateRequest: initialUpdateRequest);
        if (size.width < 640) {
          return Dialog.fullscreen(child: SafeArea(child: content));
        }
        return Dialog(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: SizedBox(
                width: size.width > 720 ? 680 : size.width - 32,
                height: size.height > 640 ? 590 : size.height * 0.9,
                child: content));
      });
}

class AdminScheduleFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final List<AdminStation> stations;
  final List<AdminRoute> routes;
  final List<AdminServiceClass> serviceClasses;
  final StructuredApiError? error;
  final AdminSchedule? initialSchedule;
  final AdminScheduleCreateRequest? initialCreateRequest;
  final AdminScheduleUpdateRequest? initialUpdateRequest;

  const AdminScheduleFormDialog({
    super.key,
    required this.isSubmitting,
    required this.stations,
    required this.routes,
    required this.serviceClasses,
    this.error,
    this.initialSchedule,
    this.initialCreateRequest,
    this.initialUpdateRequest,
  });

  @override
  State<AdminScheduleFormDialog> createState() =>
      _AdminScheduleFormDialogState();
}

class _AdminScheduleFormDialogState extends State<AdminScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _stationId;
  late String? _routeId;
  late String? _serviceClassId;
  late final TextEditingController _timeController;
  late final TextEditingController _noteController;

  bool get _isEdit => widget.initialSchedule != null;

  @override
  void initState() {
    super.initState();
    final schedule = widget.initialSchedule;
    final create = widget.initialCreateRequest;
    final update = widget.initialUpdateRequest;
    _stationId = create?.stationId ?? update?.stationId ?? schedule?.station.id;
    _routeId = create?.routeId ?? update?.routeId ?? schedule?.route?.id;
    _serviceClassId = create?.serviceClassId ??
        update?.serviceClassId ??
        schedule?.serviceClass?.id;
    _timeController = TextEditingController(
        text: create?.departureTime ??
            update?.departureTime ??
            schedule?.displayTime ??
            '');
    _noteController = TextEditingController(
        text: create?.routeNote ??
            _draftPatchText(update?.routeNote) ??
            schedule?.routeNote ??
            '');
  }

  @override
  void dispose() {
    _timeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFFF5F6FA),
      child: Column(children: [
        _Header(
            title: _isEdit ? 'Modifier l’horaire' : 'Nouvel horaire',
            onClose: widget.isSubmitting ? null : () => Navigator.pop(context)),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.error != null &&
                              widget.error?.field == null) ...[
                            StaffErrorState(
                                message: widget.error!.userMessage,
                                onRetry: null),
                            const SizedBox(height: 14),
                          ],
                          _SelectField(
                              label: 'Gare *',
                              fieldName: 'station_id',
                              value: _stationId,
                              error: widget.error,
                              enabled: !widget.isSubmitting,
                              requiredField: true,
                              items: widget.stations
                                  .map((s) => DropdownMenuItem(
                                      value: s.id, child: Text(s.name)))
                                  .toList(),
                              onChanged: (value) => setState(() {
                                    _stationId = value;
                                    if (!_filteredRoutes.any(
                                        (route) => route.id == _routeId)) {
                                      _routeId = null;
                                    }
                                  })),
                          const SizedBox(height: 12),
                          _SelectField(
                              label: 'Route *',
                              fieldName: 'route_id',
                              value: _routeId,
                              error: widget.error,
                              enabled: !widget.isSubmitting,
                              requiredField: true,
                              items: _filteredRoutes
                                  .map((r) => DropdownMenuItem(
                                      value: r.id, child: Text(r.displayLabel)))
                                  .toList(),
                              onChanged: (value) => setState(() {
                                    _routeId = value;
                                  })),
                          const SizedBox(height: 12),
                          _SelectField(
                              label: 'Classe *',
                              fieldName: 'service_class_id',
                              value: _serviceClassId,
                              error: widget.error,
                              enabled: !widget.isSubmitting,
                              requiredField: true,
                              items: widget.serviceClasses
                                  .map((c) => DropdownMenuItem(
                                      value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (value) => setState(() {
                                    _serviceClassId = value;
                                  })),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _timeController,
                              enabled: !widget.isSubmitting,
                              decoration: InputDecoration(
                                  labelText: 'Heure de départ *',
                                  hintText: '08:00',
                                  prefixIcon: const Icon(Icons.schedule),
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      widget.error?.field == 'departure_time'
                                          ? widget.error!.userMessage
                                          : null),
                              validator: _validateTime),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: _noteController,
                              enabled: !widget.isSubmitting,
                              maxLength: 255,
                              decoration: InputDecoration(
                                  labelText: 'Note route',
                                  hintText: 'Information optionnelle',
                                  border: const OutlineInputBorder(),
                                  errorText: widget.error?.field == 'route_note'
                                      ? widget.error!.userMessage
                                      : null)),
                        ])))),
        Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Annuler')),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: widget.isSubmitting ? null : _submit,
                  child: widget.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Enregistrer' : 'Créer'))
            ]))
      ]));

  List<AdminRoute> get _filteredRoutes {
    if (_stationId == null) {
      return widget.routes;
    }
    return widget.routes
        .where((route) => route.departureStation.id == _stationId)
        .toList();
  }

  String? _validateTime(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'L’heure de départ est obligatoire.';
    }
    final valid = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(trimmed);
    if (!valid) {
      return 'Utilisez le format HH:mm.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final stationId = _stationId;
    final routeId = _routeId;
    final serviceClassId = _serviceClassId;
    if (stationId == null || routeId == null || serviceClassId == null) {
      return;
    }
    if (_isEdit) {
      Navigator.pop(
          context,
          AdminScheduleFormResult.update(AdminScheduleUpdateRequest(
              stationId: _changed(stationId, widget.initialSchedule?.station.id),
              routeId: _changed(routeId, widget.initialSchedule?.route?.id),
              serviceClassId: _changed(
                  serviceClassId, widget.initialSchedule?.serviceClass?.id),
              departureTime: _changed(normalizeScheduleTime(_timeController.text),
                  widget.initialSchedule?.displayTime),
              routeNote: _nullablePatch(
                  _noteController.text, widget.initialSchedule?.routeNote))));
      return;
    }
    Navigator.pop(
        context,
        AdminScheduleFormResult.create(AdminScheduleCreateRequest(
            stationId: stationId,
            routeId: routeId,
            serviceClassId: serviceClassId,
            departureTime: _timeController.text,
            routeNote: _noteController.text)));
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const _Header({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.white,
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900))),
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
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _SelectField({
    required this.label,
    required this.fieldName,
    required this.value,
    required this.error,
    required this.enabled,
    required this.requiredField,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: error?.field == fieldName ? error!.userMessage : null),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) {
          return 'Ce champ est obligatoire.';
        }
        return null;
      });
}

String? _changed(String current, String? initial) {
  final normalized = current.trim();
  if (normalized == (initial ?? '').trim()) {
    return null;
  }
  return normalized;
}

AdminTransportPatchField<String> _nullablePatch(
    String? current, String? initial) {
  final trimmed = current?.trim() ?? '';
  final normalizedInitial = (initial ?? '').trim();
  if (trimmed == normalizedInitial) {
    return const AdminTransportPatchField.absent();
  }
  if (trimmed.isEmpty) {
    return const AdminTransportPatchField.clear();
  }
  return AdminTransportPatchField.value(trimmed);
}

String? _draftPatchText(AdminTransportPatchField<String>? field) {
  if (field == null || !field.isProvided) {
    return null;
  }
  return field.value;
}
