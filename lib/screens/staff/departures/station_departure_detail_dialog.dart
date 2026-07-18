import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';
import 'package:catrans_app/screens/staff/departures/station_departure_transition_dialog.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBg = Color(0xFFF5F6FA);
const _softPanel = Color(0xFFF7F8FC);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

Future<void> showStationDepartureDetailDialog({
  required BuildContext context,
  required StationOperationalDeparture departure,
  VoidCallback? onOpenBoarding,
  ValueChanged<StationDepartureTransitionRequest>? onTransitionRequested,
  bool isMutating = false,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final fullscreen = width < 640;

  return showDialog<void>(
    context: context,
    builder: (context) {
      final content = _StationDepartureDetailContent(
        departure: departure,
        onOpenBoarding: onOpenBoarding,
        onTransitionRequested: onTransitionRequested,
        isMutating: isMutating,
      );

      if (fullscreen) {
        return Dialog.fullscreen(
          backgroundColor: _staffBg,
          child: SafeArea(child: content),
        );
      }

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
          child: content,
        ),
      );
    },
  );
}

class _StationDepartureDetailContent extends StatelessWidget {
  final StationOperationalDeparture departure;
  final VoidCallback? onOpenBoarding;
  final ValueChanged<StationDepartureTransitionRequest>? onTransitionRequested;
  final bool isMutating;

  const _StationDepartureDetailContent({
    required this.departure,
    required this.onOpenBoarding,
    required this.onTransitionRequested,
    required this.isMutating,
  });

  @override
  Widget build(BuildContext context) {
    final canOpenBoarding =
        departure.availableActions.canOpenBoarding && onOpenBoarding != null;
    final transitionAction = _resolveTransitionAction(departure);
    final canRunTransition =
        transitionAction != null && onTransitionRequested != null;

    return Column(
      children: [
        _DialogHeader(departure: departure),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SummarySection(departure: departure),
              const SizedBox(height: 14),
              _MetricSection(departure: departure),
              const SizedBox(height: 14),
              _AlertsSection(departure: departure),
              const SizedBox(height: 14),
              _TraceSection(departure: departure),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE6E8EF))),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: isMutating ? null : () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (canOpenBoarding)
                OutlinedButton.icon(
                  onPressed: isMutating
                      ? null
                      : () {
                          Navigator.pop(context);
                          onOpenBoarding?.call();
                        },
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Ouvrir l’embarquement'),
                ),
              if (canRunTransition)
                FilledButton.icon(
                  onPressed: isMutating
                      ? null
                      : () {
                          Navigator.pop(context);
                          onTransitionRequested?.call(
                            StationDepartureTransitionRequest(
                              departure: departure,
                              action: transitionAction,
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: transitionAction.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: isMutating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(transitionAction.icon, size: 18),
                  label: Text(transitionAction.shortLabel),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _DialogHeader({required this.departure});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(departure.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Color(0xFFE6E8EF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _brandPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              departure.displayTime,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _brandPurple,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departure.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  departure.displayRoute,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(label: departure.statusLabel, color: statusColor),
                    _Badge(
                      label: departure.displayServiceClass,
                      color: _brandPurple,
                    ),
                    _Badge(
                      label: departure.capacityModeLabel,
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _SummarySection({required this.departure});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Résumé opérationnel',
      child: Column(
        children: [
          _InfoRow(label: 'Date', value: _formatDate(departure.departureDate)),
          _InfoRow(label: 'Heure', value: departure.displayTime),
          _InfoRow(label: 'Gare', value: departure.stationName),
          _InfoRow(label: 'Destination', value: departure.destinationName),
          _InfoRow(label: 'Classe', value: departure.displayServiceClass),
          _InfoRow(label: 'Statut', value: departure.statusLabel),
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _MetricSection({required this.departure});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Embarquement et capacité',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricBox(
                    width: width,
                    label: 'Voyageurs attendus',
                    value: departure.travelersExpected.toString(),
                    icon: Icons.groups_2_outlined,
                  ),
                  _MetricBox(
                    width: width,
                    label: 'Billets contrôlés',
                    value: departure.ticketsChecked.toString(),
                    icon: Icons.verified_outlined,
                  ),
                  _MetricBox(
                    width: width,
                    label: 'Restants',
                    value: departure.ticketsRemaining.toString(),
                    icon: Icons.pending_actions_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Taux d’embarquement ${departure.boardingRate.toStringAsFixed(0)} %',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: departure.progressValue,
              backgroundColor: const Color(0xFFE6E8EF),
              valueColor: const AlwaysStoppedAnimation<Color>(_success),
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Capacité', value: departure.capacityLabel),
          _InfoRow(
            label: 'Places bloquées',
            value: departure.blockedSeats.toString(),
          ),
          _InfoRow(
            label: 'Rejets validation',
            value: departure.validationRejections.toString(),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _AlertsSection({required this.departure});

  @override
  Widget build(BuildContext context) {
    final alerts = departure.alerts;
    return _Section(
      title: 'Alertes',
      child: alerts.isEmpty
          ? const Text(
              'Aucune alerte sur ce départ.',
              style: TextStyle(color: Colors.black54),
            )
          : Column(
              children: alerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertTile(alert: alert),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _TraceSection extends StatelessWidget {
  final StationOperationalDeparture departure;

  const _TraceSection({required this.departure});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Traçabilité',
      child: Column(
        children: [
          _InfoRow(
            label: 'Ouvert par',
            value: _actorLine(departure.openedByName, departure.openedAt),
          ),
          _InfoRow(
            label: 'Clôturé par',
            value: _actorLine(departure.closedByName, departure.closedAt),
          ),
          _InfoRow(
            label: 'Départ marqué par',
            value: _actorLine(departure.departedByName, departure.departedAt),
          ),
          _InfoRow(
              label: 'Prochaine action', value: departure.nextAction ?? '—'),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _brandPurple,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;

  const _MetricBox({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E8EF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _brandPurple),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: _brandPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final StationOperationalDepartureAlert alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(alert.message, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

StationDepartureTransitionAction? _resolveTransitionAction(
  StationOperationalDeparture departure,
) {
  final nextAction = departure.nextAction;
  if (nextAction == StationDepartureTransitionAction.open.code &&
      departure.availableActions.canOpen) {
    return StationDepartureTransitionAction.open;
  }
  if (nextAction == StationDepartureTransitionAction.close.code &&
      departure.availableActions.canClose) {
    return StationDepartureTransitionAction.close;
  }
  if (nextAction == StationDepartureTransitionAction.depart.code &&
      departure.availableActions.canMarkDeparted) {
    return StationDepartureTransitionAction.depart;
  }

  if (nextAction == null || nextAction.isEmpty) {
    if (departure.availableActions.canOpen) {
      return StationDepartureTransitionAction.open;
    }
    if (departure.availableActions.canClose) {
      return StationDepartureTransitionAction.close;
    }
    if (departure.availableActions.canMarkDeparted) {
      return StationDepartureTransitionAction.depart;
    }
  }

  return null;
}

String _actorLine(String? name, DateTime? date) {
  if (name == null && date == null) return '—';
  final actor = name ?? 'Agent non renseigné';
  final time = _formatDateTime(date);
  return time == '—' ? actor : '$actor • $time';
}

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} à $hour:$minute';
}

Color _statusColor(String code) {
  switch (code) {
    case 'open':
      return _success;
    case 'closed':
      return Colors.indigo;
    case 'departed':
      return Colors.blueGrey;
    case 'cancelled':
      return _danger;
    case 'scheduled':
      return _warning;
  }
  return Colors.black54;
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'error':
    case 'critical':
      return _danger;
    case 'warning':
      return _warning;
    case 'success':
      return _success;
  }
  return Colors.blueGrey;
}
