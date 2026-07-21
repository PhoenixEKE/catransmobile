import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_schedule_models.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';

Future<void> showAdminScheduleDetailDialog({
  required BuildContext context,
  required AdminSchedule schedule,
  required Future<AdminSchedule> Function(String id) loadDetail,
}) async {
  return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AdminScheduleDetailDialog(
          initialSchedule: schedule, loadDetail: loadDetail));
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
  late Future<AdminSchedule> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDetail(widget.initialSchedule.id);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      key: const Key('admin-schedule-detail-dialog'),
      title: const Text(
        'Détail horaire',
        key: Key('admin-schedule-detail-title'),
      ),
      content: SizedBox(
          width: 520,
          child: FutureBuilder<AdminSchedule>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return StaffErrorState(
                      message: 'Impossible de charger le détail horaire.',
                      onRetry: () => setState(() {
                            _future = widget.loadDetail(
                                widget.initialSchedule.id);
                          }));
                }
                final schedule = snapshot.data ?? widget.initialSchedule;
                return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row(label: 'Gare', value: schedule.station.name),
                      _Row(label: 'Route', value: schedule.displayRoute),
                      _Row(
                          label: 'Classe',
                          value: schedule.displayServiceClass),
                      _Row(label: 'Heure', value: schedule.displayTime),
                      _Row(label: 'Note', value: _display(schedule.routeNote)),
                      _Row(
                          label: 'Statut',
                          value: schedule.isActive ? 'Actif' : 'Inactif'),
                    ]);
              })),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'))
      ]);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Text(value))
      ]));
}

String _display(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
