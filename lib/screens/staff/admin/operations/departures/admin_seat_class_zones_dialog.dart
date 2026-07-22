import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_seat_class_zone_models.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_service_class_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

/// Opens the "seat zones" configuration modal for a departure template.
///
/// Returns `true` if the configuration was saved (so the caller can show a
/// confirmation), `false`/`null` otherwise.
Future<bool?> showAdminSeatClassZonesDialog({
  required BuildContext context,
  required String departureTemplateId,
  String? departureTemplateLabel,
  required AdminOperationsApiService apiService,
  AdminTransportBaseApiService? transportApiService,
}) {
  return showDialog<bool>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = _AdminSeatClassZonesDialog(
        departureTemplateId: departureTemplateId,
        departureTemplateLabel: departureTemplateLabel,
        apiService: apiService,
        transportApiService: transportApiService ?? AdminTransportBaseApiService(),
      );
      if (size.width < 640) {
        return Dialog.fullscreen(child: SafeArea(child: content));
      }
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: size.width > 680 ? 640 : size.width - 32,
          height: size.height > 640 ? 580 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class _AdminSeatClassZonesDialog extends StatefulWidget {
  final String departureTemplateId;
  final String? departureTemplateLabel;
  final AdminOperationsApiService apiService;
  final AdminTransportBaseApiService transportApiService;

  const _AdminSeatClassZonesDialog({
    required this.departureTemplateId,
    required this.departureTemplateLabel,
    required this.apiService,
    required this.transportApiService,
  });

  @override
  State<_AdminSeatClassZonesDialog> createState() =>
      _AdminSeatClassZonesDialogState();
}

class _ZoneRow {
  final int localId;
  String? serviceClassId;
  String startText;
  String endText;

  _ZoneRow({
    required this.localId,
    this.serviceClassId,
    this.startText = '',
    this.endText = '',
  });
}

class _AdminSeatClassZonesDialogState
    extends State<_AdminSeatClassZonesDialog> {
  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  String? _validationError;
  StructuredApiError? _saveError;

  List<AdminServiceClass> _serviceClasses = const [];
  final List<_ZoneRow> _rows = [];
  int _nextLocalId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final zonesPage = await widget.apiService.listSeatClassZones(
        widget.departureTemplateId,
        isActive: true,
        pageSize: 100,
      );
      final serviceClassesPage =
          await widget.transportApiService.listServiceClasses(
        isActive: true,
        ordering: 'name',
        pageSize: 100,
      );
      final zones = zonesPage.results;
      final serviceClasses = serviceClassesPage.results;
      if (!mounted) return;
      setState(() {
        _serviceClasses = serviceClasses;
        _rows
          ..clear()
          ..addAll(zones.map((zone) => _ZoneRow(
                localId: _nextLocalId++,
                serviceClassId: zone.serviceClass.id,
                startText: zone.seatNumberStart.toString(),
                endText: zone.seatNumberEnd.toString(),
              )));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Impossible de charger les zones de sièges.';
        _loading = false;
      });
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_ZoneRow(localId: _nextLocalId++));
      _validationError = null;
    });
  }

  void _removeRow(int localId) {
    setState(() {
      _rows.removeWhere((row) => row.localId == localId);
      _validationError = null;
    });
  }

  /// Mirrors the backend's own checks (`start <= end`, no overlap between
  /// ranges) so obviously-invalid input is rejected before any network
  /// call. The backend still re-validates (it also checks the ranges
  /// against the template's actual seat layout, which this client-side
  /// pass does not attempt to replicate).
  String? _validate() {
    if (_rows.isEmpty) return null;
    final parsed = <({int start, int end, int rowIndex})>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.serviceClassId == null || row.serviceClassId!.isEmpty) {
        return 'Sélectionnez une classe de service pour chaque zone (ligne ${i + 1}).';
      }
      final start = int.tryParse(row.startText.trim());
      final end = int.tryParse(row.endText.trim());
      if (start == null || end == null || start < 1 || end < 1) {
        return 'Les numéros de sièges doivent être des entiers positifs (ligne ${i + 1}).';
      }
      if (start > end) {
        return 'Le numéro de début doit être inférieur ou égal au numéro de fin (ligne ${i + 1}).';
      }
      parsed.add((start: start, end: end, rowIndex: i));
    }
    for (var i = 0; i < parsed.length; i++) {
      for (var j = i + 1; j < parsed.length; j++) {
        final a = parsed[i];
        final b = parsed[j];
        if (a.start <= b.end && b.start <= a.end) {
          return 'Les plages de sièges se chevauchent (lignes ${a.rowIndex + 1} et ${b.rowIndex + 1}).';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() {
        _validationError = validationError;
        _saveError = null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _validationError = null;
      _saveError = null;
    });
    try {
      await widget.apiService.replaceSeatClassZones(
        widget.departureTemplateId,
        _rows
            .map((row) => AdminSeatClassZoneDraft(
                  serviceClassId: row.serviceClassId!,
                  seatNumberStart: int.parse(row.startText.trim()),
                  seatNumberEnd: int.parse(row.endText.trim()),
                ))
            .toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error is ApiException
            ? StructuredApiError.fromException(error)
            : const StructuredApiError(
                detail: 'Une erreur est survenue. Veuillez réessayer.');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.event_seat_outlined, color: Color(0xFF0F056B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.departureTemplateLabel != null
                        ? 'Zones de sièges — ${widget.departureTemplateLabel}'
                        : 'Zones de sièges (Prestige)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const StaffLoadingState(message: 'Chargement des zones...');
    }
    if (_loadError != null) {
      return StaffErrorState(message: _loadError!, onRetry: _load);
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFB54708).withValues(alpha: 0.24),
                  ),
                ),
                child: const Text(
                  "Enregistrer remplace l'intégralité de la configuration "
                  "existante pour ce modèle : les zones non affichées "
                  "ci-dessous seront supprimées.",
                  style: TextStyle(
                    color: Color(0xFFB54708),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_rows.isEmpty)
                const Text(
                  'Aucune zone configurée pour ce modèle.',
                  style: TextStyle(color: Color(0xFF667085)),
                ),
              for (final row in _rows) _buildRow(row),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une zone'),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _validationError!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                StaffErrorState(message: _saveError!.userMessage),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_ZoneRow row) {
    return Padding(
      key: ValueKey(row.localId),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: row.serviceClassId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Classe de service',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _serviceClasses
                  .map((serviceClass) => DropdownMenuItem(
                        value: serviceClass.id,
                        child: Text(serviceClass.name),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => row.serviceClassId = value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: row.startText,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'De',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => row.startText = value,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: row.endText,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'À',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => row.endText = value,
            ),
          ),
          IconButton(
            tooltip: 'Supprimer la zone',
            onPressed: _saving ? null : () => _removeRow(row.localId),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318)),
          ),
        ],
      ),
    );
  }
}
