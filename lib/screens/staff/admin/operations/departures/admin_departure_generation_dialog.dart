import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_seat_class_zone_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_route_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_station_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';

Future<void> showAdminDepartureGenerationDialog({
  required BuildContext context,
  required List<AdminOperationRecord> templates,
  required Future<Map<String, dynamic>> Function(
    String templateId,
    AdminDepartureDatesRequest request,
  ) previewGeneration,
  required Future<AdminDepartureGenerationResult?> Function(
    String templateId,
    AdminDepartureDatesRequest request,
  ) generateDepartures,
  required bool isSubmitting,
  required AdminOperationsApiService apiService,
  AdminTransportBaseApiService? transportApiService,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => _AdminDepartureGenerationDialog(
      templates: templates,
      previewGeneration: previewGeneration,
      generateDepartures: generateDepartures,
      apiService: apiService,
      transportApiService:
          transportApiService ?? AdminTransportBaseApiService(),
    ),
  );
}

class _AdminDepartureGenerationDialog extends StatefulWidget {
  final List<AdminOperationRecord> templates;
  final Future<Map<String, dynamic>> Function(
    String templateId,
    AdminDepartureDatesRequest request,
  ) previewGeneration;
  final Future<AdminDepartureGenerationResult?> Function(
    String templateId,
    AdminDepartureDatesRequest request,
  ) generateDepartures;
  final AdminOperationsApiService apiService;
  final AdminTransportBaseApiService transportApiService;

  const _AdminDepartureGenerationDialog({
    required this.templates,
    required this.previewGeneration,
    required this.generateDepartures,
    required this.apiService,
    required this.transportApiService,
  });

  @override
  State<_AdminDepartureGenerationDialog> createState() =>
      _AdminDepartureGenerationDialogState();
}

class _AdminDepartureGenerationDialogState
    extends State<_AdminDepartureGenerationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController(text: '08:00');
  final _capacityController = TextEditingController(text: '40');
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _zoneStartController = TextEditingController();
  final _zoneEndController = TextEditingController();

  late List<AdminOperationRecord> _templates;
  List<AdminStation> _stations = const [];
  List<AdminRoute> _routes = const [];
  List<AdminServiceClass> _serviceClasses = const [];
  List<AdminOperationRecord> _seatLayouts = const [];

  bool _useExistingTemplate = true;
  bool _useExistingSeatLayout = false;
  bool _loadingRefs = true;
  bool _previewing = false;
  bool _generating = false;
  String? _error;
  String? _resolvedTemplateId;
  String? _templateId;
  String? _stationId;
  String? _routeId;
  String? _serviceClassId;
  String? _seatLayoutId;
  Map<String, dynamic>? _previewData;

  bool get _isBusy => _loadingRefs || _previewing || _generating;

  AdminServiceClass? get _selectedServiceClass {
    final id = _serviceClassId;
    if (id == null) return null;
    for (final serviceClass in _serviceClasses) {
      if (serviceClass.id == id) return serviceClass;
    }
    return null;
  }

  bool get _selectedClassIsPrestige =>
      (_selectedServiceClass?.code.toUpperCase() ?? '') == 'PRESTIGE';

  Iterable<AdminRoute> get _availableRoutes {
    final stationId = _stationId;
    if (stationId == null || stationId.isEmpty) return _routes;
    return _routes.where((route) => route.departureStation.id == stationId);
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startController.text = _formatDate(today);
    _endController.text = _formatDate(today);
    _templates = List.of(widget.templates);
    _useExistingTemplate = _templates.isNotEmpty;
    _templateId = _templates.isNotEmpty ? _templates.first.id : null;
    _loadReferences();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _capacityController.dispose();
    _startController.dispose();
    _endController.dispose();
    _zoneStartController.dispose();
    _zoneEndController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingRefs = true;
      _error = null;
    });
    try {
      final stationsPage = await widget.transportApiService.listStations(
        isActive: true,
        ordering: 'name',
        pageSize: 100,
      );
      final routesPage = await widget.transportApiService.listRoutes(
        isActive: true,
        ordering: 'destination_name_snapshot',
        pageSize: 100,
      );
      final serviceClassesPage =
          await widget.transportApiService.listServiceClasses(
        isActive: true,
        ordering: 'name',
        pageSize: 100,
      );
      final seatLayoutsPage = await widget.apiService.listSeatLayouts(
        isActive: true,
        ordering: 'name',
        pageSize: 100,
      );
      if (!mounted) return;
      setState(() {
        _stations = stationsPage.results;
        _routes = routesPage.results;
        _serviceClasses = serviceClassesPage.results;
        _seatLayouts = seatLayoutsPage.results;
        _stationId = _stations.isNotEmpty ? _stations.first.id : null;
        _serviceClassId =
            _serviceClasses.isNotEmpty ? _serviceClasses.first.id : null;
        _routeId = _availableRoutes.isNotEmpty
            ? _availableRoutes.first.id
            : (_routes.isNotEmpty ? _routes.first.id : null);
        _useExistingSeatLayout = _seatLayouts.isNotEmpty;
        _seatLayoutId = _seatLayouts.isNotEmpty ? _seatLayouts.first.id : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingRefs = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 0 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : 820,
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
                  'Nouveau départ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_loadingRefs) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 16),
                ],
                const _SectionTitle(number: 1, label: 'Gabarit'),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.event_available_outlined),
                      label: Text('Existant'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Nouveau'),
                    ),
                  ],
                  selected: {_useExistingTemplate},
                  onSelectionChanged: _isBusy
                      ? null
                      : (values) => setState(() {
                            _useExistingTemplate = values.first;
                            _markConfigDirty();
                          }),
                ),
                const SizedBox(height: 12),
                if (_useExistingTemplate)
                  DropdownButtonFormField<String>(
                    key: const Key('admin-departure-template-field'),
                    initialValue: _templateId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Gabarit'),
                    items: _templates
                        .map(
                          (template) => DropdownMenuItem(
                            value: template.id,
                            child: Text(_templateLabel(template)),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        _useExistingTemplate && (value == null || value.isEmpty)
                            ? 'Le gabarit est obligatoire.'
                            : null,
                    onChanged: _isBusy
                        ? null
                        : (value) => setState(() {
                              _templateId = value;
                              _markConfigDirty();
                            }),
                  )
                else
                  _buildNewTemplateFields(compact),
                const SizedBox(height: 16),
                if (!_useExistingTemplate) ...[
                  const _SectionTitle(number: 2, label: 'Plan de sièges'),
                  const SizedBox(height: 8),
                  _buildSeatLayoutFields(),
                  const SizedBox(height: 16),
                ],
                if (!_useExistingTemplate && _selectedClassIsPrestige) ...[
                  const _SectionTitle(number: 3, label: 'Plage Prestige'),
                  const SizedBox(height: 8),
                  _buildDateOrRangeRow(
                    compact: compact,
                    first: TextFormField(
                      key: const Key('admin-departure-zone-start-field'),
                      controller: _zoneStartController,
                      decoration: const InputDecoration(labelText: 'Début'),
                      keyboardType: TextInputType.number,
                      validator: _validatePrestigeSeatNumber,
                      onChanged: (_) => _markConfigDirty(),
                      enabled: !_isBusy,
                    ),
                    second: TextFormField(
                      key: const Key('admin-departure-zone-end-field'),
                      controller: _zoneEndController,
                      decoration: const InputDecoration(labelText: 'Fin'),
                      keyboardType: TextInputType.number,
                      validator: _validatePrestigeSeatNumber,
                      onChanged: (_) => _markConfigDirty(),
                      enabled: !_isBusy,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const _SectionTitle(number: 4, label: 'Date(s)'),
                const SizedBox(height: 8),
                _buildDateOrRangeRow(
                  compact: compact,
                  first: TextFormField(
                    key: const Key('admin-departure-start-date-field'),
                    controller: _startController,
                    decoration:
                        const InputDecoration(labelText: 'Début YYYY-MM-DD'),
                    validator: _validateDate,
                    onChanged: (_) => _markConfigDirty(),
                    enabled: !_isBusy,
                  ),
                  second: TextFormField(
                    key: const Key('admin-departure-end-date-field'),
                    controller: _endController,
                    decoration:
                        const InputDecoration(labelText: 'Fin YYYY-MM-DD'),
                    validator: _validateDate,
                    onChanged: (_) => _markConfigDirty(),
                    enabled: !_isBusy,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 16),
                if (_previewing || _generating) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 12),
                ],
                if (_previewData != null) ...[
                  _ResultHeader(
                    title: 'Aperçu',
                    subtitle: _previewSummary(_previewData!),
                  ),
                  const SizedBox(height: 10),
                  _PreviewList(previewData: _previewData!),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: (_previewing || _generating)
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                    OutlinedButton(
                      key: const Key('admin-departure-preview-submit'),
                      onPressed: _isBusy ? null : _preview,
                      child: const Text('Prévisualiser'),
                    ),
                    ElevatedButton(
                      key: const Key('admin-departure-generate-submit'),
                      onPressed: _isBusy ? null : _generate,
                      child: const Text('Générer les départs'),
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

  Widget _buildSeatLayoutFields() {
    final hasExistingLayouts = _seatLayouts.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.event_seat_outlined),
              label: Text('Existant'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.add_circle_outline),
              label: Text('Capacité'),
            ),
          ],
          selected: {_useExistingSeatLayout && hasExistingLayouts},
          onSelectionChanged: _isBusy || !hasExistingLayouts
              ? null
              : (values) => setState(() {
                    _useExistingSeatLayout = values.first;
                    _markConfigDirty();
                  }),
        ),
        const SizedBox(height: 12),
        if (_useExistingSeatLayout && hasExistingLayouts)
          DropdownButtonFormField<String>(
            key: const Key('admin-departure-layout-existing-field'),
            initialValue: _seatLayoutId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Plan de sièges'),
            items: _seatLayouts
                .map(
                  (layout) => DropdownMenuItem(
                    value: layout.id,
                    child: Text(_seatLayoutLabel(layout)),
                  ),
                )
                .toList(),
            validator: (value) =>
                !_useExistingTemplate && _useExistingSeatLayout &&
                        (value == null || value.isEmpty)
                    ? 'Le plan de sièges est obligatoire.'
                    : null,
            onChanged: _isBusy
                ? null
                : (value) => setState(() {
                      _seatLayoutId = value;
                      _markConfigDirty();
                    }),
          )
        else
          TextFormField(
            key: const Key('admin-departure-layout-capacity-field'),
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'Capacité',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_useExistingTemplate || _useExistingSeatLayout) return null;
              final capacity = int.tryParse(value?.trim() ?? '');
              if (capacity == null || capacity < 1) {
                return 'La capacité doit être un entier positif.';
              }
              if (capacity > 200) {
                return 'La capacité maximale est 200.';
              }
              return null;
            },
            onChanged: (_) => _markConfigDirty(),
            enabled: !_isBusy,
          ),
      ],
    );
  }

  String _seatLayoutLabel(AdminOperationRecord layout) {
    final totalSeats = layout.raw['total_seats'];
    return totalSeats == null
        ? layout.name
        : '${layout.name} ($totalSeats places)';
  }

  Widget _buildNewTemplateFields(bool compact) {
    final routeItems = _availableRoutes.toList();
    if (_routeId != null && !routeItems.any((route) => route.id == _routeId)) {
      _routeId = routeItems.isNotEmpty ? routeItems.first.id : null;
    }
    return Column(
      children: [
        _buildDateOrRangeRow(
          compact: compact,
          first: DropdownButtonFormField<String>(
            key: const Key('admin-departure-station-field'),
            initialValue: _stationId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Gare'),
            items: _stations
                .map((station) => DropdownMenuItem(
                      value: station.id,
                      child: Text(station.name),
                    ))
                .toList(),
            validator: (value) =>
                !_useExistingTemplate && (value == null || value.isEmpty)
                    ? 'La gare est obligatoire.'
                    : null,
            onChanged: _isBusy
                ? null
                : (value) => setState(() {
                      _stationId = value;
                      final routes = _availableRoutes.toList();
                      _routeId = routes.isNotEmpty ? routes.first.id : null;
                      _markConfigDirty();
                    }),
          ),
          second: DropdownButtonFormField<String>(
            key: const Key('admin-departure-route-field'),
            initialValue: _routeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Route'),
            items: routeItems
                .map((route) => DropdownMenuItem(
                      value: route.id,
                      child: Text(route.displayLabel),
                    ))
                .toList(),
            validator: (value) =>
                !_useExistingTemplate && (value == null || value.isEmpty)
                    ? 'La route est obligatoire.'
                    : null,
            onChanged: _isBusy
                ? null
                : (value) => setState(() {
                      _routeId = value;
                      _markConfigDirty();
                    }),
          ),
        ),
        const SizedBox(height: 12),
        _buildDateOrRangeRow(
          compact: compact,
          first: DropdownButtonFormField<String>(
            key: const Key('admin-departure-service-class-field'),
            initialValue: _serviceClassId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Classe'),
            items: _serviceClasses
                .map((serviceClass) => DropdownMenuItem(
                      value: serviceClass.id,
                      child: Text(serviceClass.name),
                    ))
                .toList(),
            validator: (value) =>
                !_useExistingTemplate && (value == null || value.isEmpty)
                    ? 'La classe est obligatoire.'
                    : null,
            onChanged: _isBusy
                ? null
                : (value) => setState(() {
                      _serviceClassId = value;
                      _markConfigDirty();
                    }),
          ),
          second: TextFormField(
            key: const Key('admin-departure-time-field'),
            controller: _timeController,
            decoration: const InputDecoration(labelText: 'Horaire HH:MM'),
            validator: (value) {
              if (_useExistingTemplate) return null;
              final text = value?.trim() ?? '';
              if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
                return 'Format attendu : HH:MM.';
              }
              return null;
            },
            onChanged: (_) => _markConfigDirty(),
            enabled: !_isBusy,
          ),
        ),
      ],
    );
  }

  Widget _buildDateOrRangeRow({
    required bool compact,
    required Widget first,
    required Widget second,
  }) {
    if (compact) {
      return Column(children: [first, const SizedBox(height: 12), second]);
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _previewing = true;
      _error = null;
    });
    try {
      final templateId = await _resolveTemplateId();
      final data = await widget.previewGeneration(
        templateId,
        AdminDepartureDatesRequest(departureDates: _dateRange()),
      );
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final templateId = await _resolveTemplateId();
      final result = await widget.generateDepartures(
        templateId,
        AdminDepartureDatesRequest(departureDates: _dateRange()),
      );
      if (!mounted || result == null) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.createdCount} départ(s) créé(s)'
            '${result.existingCount > 0 ? ' · ${result.existingCount} déjà existant(s)' : ''}.',
          ),
        ),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(error));
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<String> _resolveTemplateId() async {
    if (_useExistingTemplate) {
      final templateId = _templateId;
      if (templateId == null || templateId.isEmpty) {
        throw StateError('Le gabarit est obligatoire.');
      }
      _resolvedTemplateId = templateId;
      return templateId;
    }
    if (_resolvedTemplateId != null) return _resolvedTemplateId!;

    final layoutId = await _resolveSeatLayoutId();
    final schedule = await _resolveSchedule();
    final template = await widget.apiService.createDepartureTemplate(
      AdminDepartureTemplateWriteRequest(
        scheduleId: schedule.id,
        seatLayoutId: layoutId,
      ),
    );
    if (_selectedClassIsPrestige) {
      await widget.apiService.replaceSeatClassZones(
        template.id,
        [
          AdminSeatClassZoneDraft(
            serviceClassId: _serviceClassId!,
            seatNumberStart: int.parse(_zoneStartController.text.trim()),
            seatNumberEnd: int.parse(_zoneEndController.text.trim()),
          ),
        ],
      );
    }
    _templates = [template, ..._templates];
    _templateId = template.id;
    _resolvedTemplateId = template.id;
    return template.id;
  }

  Future<String> _resolveSeatLayoutId() async {
    if (_useExistingSeatLayout) {
      final layoutId = _seatLayoutId;
      if (layoutId == null || layoutId.isEmpty) {
        throw StateError('Le plan de sièges est obligatoire.');
      }
      return layoutId;
    }
    final capacity = int.parse(_capacityController.text.trim());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final layout = await widget.apiService.createSeatLayout(
      AdminSeatLayoutWriteRequest(
        name: 'Bus $capacity places $timestamp',
        capacity: capacity,
      ),
    );
    return layout.id;
  }

  Future<AdminSchedule> _resolveSchedule() async {
    final stationId = _stationId!;
    final routeId = _routeId!;
    final serviceClassId = _serviceClassId!;
    final departureTime = normalizeScheduleTime(_timeController.text);
    final schedules = await widget.transportApiService.listSchedules(
      stationId: stationId,
      routeId: routeId,
      serviceClassId: serviceClassId,
      departureTime: departureTime,
      isActive: true,
      pageSize: 1,
    );
    if (schedules.results.isNotEmpty) return schedules.results.first;
    return widget.transportApiService.createSchedule(
      AdminScheduleCreateRequest(
        stationId: stationId,
        routeId: routeId,
        serviceClassId: serviceClassId,
        departureTime: departureTime,
      ),
    );
  }

  void _markConfigDirty() {
    _resolvedTemplateId = null;
    _previewData = null;
    _error = null;
  }

  List<String> _dateRange() {
    final start = DateTime.parse(_startController.text.trim());
    final end = DateTime.parse(_endController.text.trim());
    final first = start.isBefore(end) ? start : end;
    final last = start.isBefore(end) ? end : start;
    final dates = <String>[];
    var current = DateTime(first.year, first.month, first.day);
    final lastDate = DateTime(last.year, last.month, last.day);
    while (!current.isAfter(lastDate)) {
      dates.add(_formatDate(current));
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  String? _validateDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'La date est obligatoire.';
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return 'Format attendu : YYYY-MM-DD.';
    }
    return null;
  }

  String? _validatePrestigeSeatNumber(String? value) {
    if (!_selectedClassIsPrestige) return null;
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) {
      return 'Entier positif obligatoire.';
    }
    final start = int.tryParse(_zoneStartController.text.trim());
    final end = int.tryParse(_zoneEndController.text.trim());
    if (start != null && end != null && start > end) {
      return 'La plage est invalide.';
    }
    return null;
  }

  String _templateLabel(AdminOperationRecord template) {
    final raw = template.raw;
    final station = raw['station'];
    final route = raw['route'];
    final serviceClass = raw['service_class'];
    final time = raw['departure_time']?.toString();
    final stationName = station is Map ? station['name']?.toString() : null;
    final routeName = route is Map
        ? (route['label'] ?? route['destination_name'])?.toString()
        : null;
    final className =
        serviceClass is Map ? serviceClass['name']?.toString() : null;
    return [stationName, routeName, className, time]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' · ');
  }

  String _previewSummary(Map<String, dynamic> previewData) {
    final results = previewData['results'];
    if (results is! List) return 'Aucun aperçu exploitable.';
    final validCount =
        results.whereType<Map>().where((item) => item['valid'] == true).length;
    final existingCount = results
        .whereType<Map>()
        .where((item) => item['already_exists'] == true)
        .length;
    return '$validCount date(s) valide(s) · $existingCount déjà existant(s)';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return error.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  final int number;
  final String label;

  const _SectionTitle({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$number. $label',
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ResultHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF667085))),
      ],
    );
  }
}

class _PreviewList extends StatelessWidget {
  final Map<String, dynamic> previewData;

  const _PreviewList({required this.previewData});

  @override
  Widget build(BuildContext context) {
    final results = previewData['results'];
    if (results is! List || results.isEmpty) {
      return const Text('Aucune date à prévisualiser.');
    }
    return Column(
      children: results.whereType<Map>().map((item) {
        final valid = item['valid'] == true;
        final existing = item['already_exists'] == true;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E7EF)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(item['departure_date']?.toString() ?? '-')),
              _MiniBadge(
                label: valid ? 'Valide' : 'Invalide',
                color:
                    valid ? const Color(0xFF027A48) : const Color(0xFFB42318),
              ),
              const SizedBox(width: 6),
              _MiniBadge(
                label: existing ? 'Existe' : 'Nouveau',
                color: existing
                    ? const Color(0xFFB54708)
                    : const Color(0xFF0F056B),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
