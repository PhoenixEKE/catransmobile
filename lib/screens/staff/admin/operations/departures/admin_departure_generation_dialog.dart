import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/admin_operations_models.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_departure_models.dart';

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
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogContext) => _AdminDepartureGenerationDialog(
      templates: templates,
      previewGeneration: previewGeneration,
      generateDepartures: generateDepartures,
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

  const _AdminDepartureGenerationDialog({
    required this.templates,
    required this.previewGeneration,
    required this.generateDepartures,
  });

  @override
  State<_AdminDepartureGenerationDialog> createState() =>
      _AdminDepartureGenerationDialogState();
}

class _AdminDepartureGenerationDialogState
    extends State<_AdminDepartureGenerationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String? _templateId;
  Map<String, dynamic>? _previewData;
  AdminDepartureGenerationResult? _generationResult;
  bool _previewing = false;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _startController.text = _formatDate(today);
    _endController.text = _formatDate(today.add(const Duration(days: 6)));
    _templateId =
        widget.templates.isNotEmpty ? widget.templates.first.id : null;
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 0 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : 760,
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
                  'Générer des départs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Le backend déduplique les départs existants: la prévisualisation montre le résultat attendu avant génération.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _templateId,
                  decoration: const InputDecoration(labelText: 'Template'),
                  items: widget.templates
                      .map(
                        (template) => DropdownMenuItem(
                          value: template.id,
                          child: Text(_templateLabel(template)),
                        ),
                      )
                      .toList(),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Le template est obligatoire.'
                      : null,
                  onChanged: (_previewing || _generating)
                      ? null
                      : (value) => setState(() => _templateId = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startController,
                        decoration: const InputDecoration(
                            labelText: 'Début (YYYY-MM-DD)'),
                        validator: _validateDate,
                        enabled: !_previewing && !_generating,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endController,
                        decoration: const InputDecoration(
                            labelText: 'Fin (YYYY-MM-DD)'),
                        validator: _validateDate,
                        enabled: !_previewing && !_generating,
                      ),
                    ),
                  ],
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
                    title: 'Prévisualisation',
                    subtitle: _previewSummary(_previewData!),
                  ),
                  const SizedBox(height: 10),
                  _PreviewList(previewData: _previewData!),
                  const SizedBox(height: 16),
                ],
                if (_generationResult != null) ...[
                  _ResultHeader(
                    title: 'Résultat réel',
                    subtitle:
                        'Créés: ${_generationResult!.createdCount} · Déjà existants: ${_generationResult!.existingCount}',
                  ),
                  const SizedBox(height: 10),
                  _GenerationList(result: _generationResult!),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: (_previewing || _generating)
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: (_previewing || _generating) ? null : _preview,
                      child: const Text('Prévisualiser'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          (_previewing || _generating) ? null : _generate,
                      child: const Text('Générer'),
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

  Future<void> _preview() async {
    if (!_formKey.currentState!.validate()) return;
    final templateId = _templateId;
    if (templateId == null) return;
    final request = AdminDepartureDatesRequest(departureDates: _dateRange());
    setState(() {
      _previewing = true;
      _error = null;
      _generationResult = null;
    });
    try {
      final data = await widget.previewGeneration(templateId, request);
      if (!mounted) return;
      setState(() => _previewData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (!mounted) return;
      setState(() => _previewing = false);
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final templateId = _templateId;
    if (templateId == null) return;
    final request = AdminDepartureDatesRequest(departureDates: _dateRange());
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final result = await widget.generateDepartures(templateId, request);
      if (!mounted || result == null) return;
      setState(() => _generationResult = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (!mounted) return;
      setState(() => _generating = false);
    }
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

  String _templateLabel(AdminOperationRecord template) {
    final raw = template.raw;
    final station = raw['station'];
    final serviceClass = raw['service_class'];
    final time = raw['departure_time']?.toString();
    final stationName = station is Map ? station['name']?.toString() : null;
    final className =
        serviceClass is Map ? serviceClass['name']?.toString() : null;
    return [stationName, className, time]
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
                  color: valid
                      ? const Color(0xFF027A48)
                      : const Color(0xFFB42318)),
              const SizedBox(width: 6),
              _MiniBadge(
                  label: existing ? 'Existe' : 'Nouveau',
                  color: existing
                      ? const Color(0xFFB54708)
                      : const Color(0xFF0F056B)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GenerationList extends StatelessWidget {
  final AdminDepartureGenerationResult result;

  const _GenerationList({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.departures.isEmpty) {
      return const Text('Aucun départ généré.');
    }
    return Column(
      children: result.departures.map((item) {
        final created = item.created;
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
              Expanded(child: Text(item.departureDate)),
              _MiniBadge(
                  label: created ? 'Créé' : 'Existant',
                  color: created
                      ? const Color(0xFF027A48)
                      : const Color(0xFF667085)),
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
