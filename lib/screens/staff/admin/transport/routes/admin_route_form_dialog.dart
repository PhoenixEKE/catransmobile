import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_city_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

class AdminRouteFormResult {
  final AdminRouteCreateRequest? createRequest;
  final AdminRouteUpdateRequest? updateRequest;
  const AdminRouteFormResult.create(this.createRequest) : updateRequest = null;
  const AdminRouteFormResult.update(this.updateRequest) : createRequest = null;
}

Future<AdminRouteFormResult?> showAdminRouteFormDialog(
    {required BuildContext context,
    required bool isSubmitting,
    required List<AdminCompany> companies,
    required List<AdminStation> stations,
    required List<AdminCity> cities,
    StructuredApiError? error,
    AdminRoute? initialRoute,
    AdminRouteCreateRequest? initialCreateRequest,
    AdminRouteUpdateRequest? initialUpdateRequest}) {
  return showDialog<AdminRouteFormResult>(
      context: context,
      useSafeArea: true,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final content = AdminRouteFormDialog(
            isSubmitting: isSubmitting,
            companies: companies,
            stations: stations,
            cities: cities,
            error: error,
            initialRoute: initialRoute,
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
                width: size.width > 760 ? 720 : size.width - 32,
                height: size.height > 760 ? 700 : size.height * 0.9,
                child: content));
      });
}

class AdminRouteFormDialog extends StatefulWidget {
  final bool isSubmitting;
  final List<AdminCompany> companies;
  final List<AdminStation> stations;
  final List<AdminCity> cities;
  final StructuredApiError? error;
  final AdminRoute? initialRoute;
  final AdminRouteCreateRequest? initialCreateRequest;
  final AdminRouteUpdateRequest? initialUpdateRequest;
  const AdminRouteFormDialog(
      {super.key,
      required this.isSubmitting,
      required this.companies,
      required this.stations,
      required this.cities,
      this.error,
      this.initialRoute,
      this.initialCreateRequest,
      this.initialUpdateRequest});
  @override
  State<AdminRouteFormDialog> createState() => _AdminRouteFormDialogState();
}

class _AdminRouteFormDialogState extends State<AdminRouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _destinationNameController;
  String? _companyId;
  String? _departureStationId;
  String? _departureCityId;
  String? _destinationCityId;
  bool get _isEdit => widget.initialRoute != null;

  @override
  void initState() {
    super.initState();
    final route = widget.initialRoute;
    final create = widget.initialCreateRequest;
    final update = widget.initialUpdateRequest;
    _companyId = create?.companyId ?? update?.companyId ?? route?.company.id;
    _departureStationId = create?.departureStationId ??
        update?.departureStationId ??
        route?.departureStation.id;
    _departureCityId = create?.departureCityId ??
        _draftPatchText(update?.departureCityId) ??
        route?.departureCity?.id;
    _destinationCityId = create?.destinationCityId ??
        _draftPatchText(update?.destinationCityId) ??
        route?.destinationCity?.id;
    _destinationNameController = TextEditingController(
        text: create?.destinationName ??
            _draftPatchText(update?.destinationName) ??
            (route?.destinationCity == null ? route?.destinationName : '') ??
            '');
  }

  @override
  void dispose() {
    _destinationNameController.dispose();
    super.dispose();
  }

  List<AdminStation> get _filteredStations {
    if (_companyId == null) {
      return widget.stations;
    }
    return widget.stations
        .where((station) => station.company.id == _companyId)
        .toList();
  }

  @override
  Widget build(BuildContext context) => Material(
      color: const Color(0xFFF5F6FA),
      child: Column(children: [
        _Header(
            title: _isEdit ? 'Modifier la route' : 'Nouvelle route',
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
                      label: 'Compagnie',
                      fieldName: 'company_id',
                      value: _companyId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      requiredField: true,
                      items: widget.companies
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) => setState(() {
                            _companyId = value;
                            if (!_filteredStations.any((station) =>
                                station.id == _departureStationId)) {
                              _departureStationId = null;
                            }
                          })),
                  const SizedBox(height: 12),
                  _SelectField(
                      label: 'Gare de départ',
                      fieldName: 'departure_station_id',
                      value: _departureStationId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      requiredField: true,
                      items: _filteredStations
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _departureStationId = value)),
                  const SizedBox(height: 12),
                  _SelectField(
                      label: 'Ville de départ',
                      fieldName: 'departure_city_id',
                      value: _departureCityId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Aucune ville')),
                        ...widget.cities.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                      ],
                      onChanged: (value) =>
                          setState(() => _departureCityId = value)),
                  const SizedBox(height: 12),
                  _SelectField(
                      label: 'Destination ville',
                      fieldName: 'destination_city_id',
                      value: _destinationCityId,
                      error: widget.error,
                      enabled: !widget.isSubmitting,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Nom libre')),
                        ...widget.cities.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                      ],
                      onChanged: (value) => setState(() {
                            _destinationCityId = value;
                            if (value != null) {
                              _destinationNameController.clear();
                            }
                          })),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _destinationNameController,
                      enabled:
                          !widget.isSubmitting && _destinationCityId == null,
                      decoration: InputDecoration(
                          labelText: 'Destination libre',
                          border: const OutlineInputBorder(),
                          errorText: widget.error?.field == 'destination_name'
                              ? widget.error!.userMessage
                              : null),
                      validator: (_) {
                        if (_destinationCityId == null &&
                            _destinationNameController.text.trim().isEmpty) {
                          return 'Une destination est obligatoire.';
                        }
                        return null;
                      }),
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
                      : Icon(_isEdit ? Icons.save_outlined : Icons.add),
                  label: Text(_isEdit ? 'Enregistrer' : 'Créer'))
            ])),
      ]));

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isEdit) {
      Navigator.pop(
          context, AdminRouteFormResult.update(_buildUpdateRequest()));
      return;
    }
    Navigator.pop(
        context,
        AdminRouteFormResult.create(AdminRouteCreateRequest(
            companyId: _companyId!,
            departureStationId: _departureStationId!,
            departureCityId: _departureCityId,
            destinationCityId: _destinationCityId,
            destinationName: _destinationCityId == null
                ? _destinationNameController.text
                : null)));
  }

  AdminRouteUpdateRequest _buildUpdateRequest() {
    final route = widget.initialRoute!;
    return AdminRouteUpdateRequest(
        companyId: _companyId == route.company.id ? null : _companyId,
        departureStationId: _departureStationId == route.departureStation.id
            ? null
            : _departureStationId,
        departureCityId:
            _nullablePatch(_departureCityId, route.departureCity?.id),
        destinationCityId:
            _nullablePatch(_destinationCityId, route.destinationCity?.id),
        destinationName: _destinationCityId == null
            ? _nullablePatch(_destinationNameController.text,
                route.destinationCity == null ? route.destinationName : null)
            : const AdminTransportPatchField.clear());
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
    return field.value ?? '';
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
        const Icon(Icons.alt_route, color: Color(0xFF0F056B)),
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
