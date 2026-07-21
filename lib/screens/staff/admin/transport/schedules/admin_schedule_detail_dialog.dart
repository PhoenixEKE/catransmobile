import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

Future<void> showAdminScheduleDetailDialog({
  required BuildContext context,
  required AdminSchedule schedule,
  required Future<AdminSchedule> Function(String id) loadDetail,
}) async {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = _AdminScheduleDetailDialog(
        initialSchedule: schedule,
        loadDetail: loadDetail,
      );
      if (size.width < 640) {
        return Dialog.fullscreen(child: SafeArea(child: content));
      }
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: size.width > 720 ? 680 : size.width - 32,
          height: size.height > 640 ? 590 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class _AdminScheduleDetailDialog extends StatefulWidget {
  final AdminSchedule initialSchedule;
  final Future<AdminSchedule> Function(String id) loadDetail;

  const _AdminScheduleDetailDialog({
    required this.initialSchedule,
    required this.loadDetail,
  });

  @override
  State<_AdminScheduleDetailDialog> createState() =>
      _AdminScheduleDetailDialogState();
}

class _AdminScheduleDetailDialogState
    extends State<_AdminScheduleDetailDialog> {
  AdminSchedule? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await widget.loadDetail(widget.initialSchedule.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _detail ?? widget.initialSchedule;
    return Material(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          _Header(schedule: schedule, onClose: () => Navigator.pop(context)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _buildBody(schedule),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AdminSchedule schedule) {
    if (_isLoading) {
      return const StaffLoadingState(message: 'Chargement de l’horaire...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }
    return SingleChildScrollView(
      child: _Section(
        title: 'Informations horaire',
        rows: [
          _Row('Gare', schedule.station.name),
          _Row('Route', schedule.displayRoute),
          _Row('Classe', schedule.displayServiceClass),
          _Row('Heure', schedule.displayTime),
          _Row('Note', _display(schedule.routeNote)),
          _Row('Statut', schedule.isActive ? 'Actif' : 'Inactif'),
        ],
      ),
    );
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return StructuredApiError.fromException(error).userMessage;
    }
    return 'Impossible de charger le détail horaire.';
  }
}

class _Header extends StatelessWidget {
  final AdminSchedule schedule;
  final VoidCallback onClose;

  const _Header({required this.schedule, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Color(0xFF0F056B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              schedule.displaySummary,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          Text(
            schedule.isActive ? 'Actif' : 'Inactif',
            style: TextStyle(
              color: schedule.isActive
                  ? const Color(0xFF157347)
                  : const Color(0xFFB42318),
              fontWeight: FontWeight.w800,
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

class _Section extends StatelessWidget {
  final String title;
  final List<_Row> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              key: const Key('admin-schedule-detail-title'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(row.label,
                          style: const TextStyle(color: Color(0xFF666A76))),
                    ),
                    Expanded(child: Text(_display(row.value))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;

  const _Row(this.label, this.value);
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
