import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/reports/station_cancellation.dart';
import 'package:catrans_app/models/station/reports/station_cancellation_detail.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change_detail.dart';
import 'package:catrans_app/screens/staff/reports/station_report_actions.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_ui_helpers.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBg = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);
const _warning = Color(0xFFB8860B);

class StationReportActionDialogResult {
  final String? reason;

  const StationReportActionDialogResult({this.reason});
}

class StationReportActionDialogData {
  final StationReportRequestKind kind;
  final StationReportActionKind action;
  final String reference;
  final String reservationReference;
  final String customerLabel;
  final String customerPhone;
  final String statusLabel;
  final StationReportEligibility eligibility;
  final List<StationReportActionInfo> infos;
  final List<String> consequences;
  final List<String> warnings;

  const StationReportActionDialogData({
    required this.kind,
    required this.action,
    required this.reference,
    required this.reservationReference,
    required this.customerLabel,
    required this.customerPhone,
    required this.statusLabel,
    required this.eligibility,
    required this.infos,
    required this.consequences,
    required this.warnings,
  });

  factory StationReportActionDialogData.fromChange(
    StationReservationChange change,
    StationReportActionKind action,
  ) {
    final infos = <StationReportActionInfo>[
      StationReportActionInfo('Référence demande', change.reference),
      StationReportActionInfo('Réservation', change.reservationReference),
      StationReportActionInfo('Client', change.customerName ?? 'Client'),
      StationReportActionInfo('Téléphone', change.customerPhone),
      StationReportActionInfo(
        'Départ actuel',
        _departureLabel(change.currentDepartureSummary),
      ),
      StationReportActionInfo(
        'Départ demandé',
        _departureLabel(change.requestedDepartureSummary),
      ),
      StationReportActionInfo(
        'Classe',
        change.requestedDepartureSummary?.serviceClassName ??
            change.requestedDepartureSummary?.serviceClassCode ??
            change.currentDepartureSummary?.serviceClassName ??
            change.currentDepartureSummary?.serviceClassCode ??
            '-',
      ),
      StationReportActionInfo(
        'Éligibilité',
        stationReportEligibilityMessage(change.eligibility),
      ),
    ];

    if (change is StationReservationChangeDetail) {
      for (final item in change.items.take(3)) {
        infos.addAll([
          StationReportActionInfo(
            'Voyageur',
            item.traveler.fullName.isEmpty
                ? 'Voyageur'
                : item.traveler.fullName,
          ),
          StationReportActionInfo(
            'Ancien siège',
            formatStationReportSeat(item.oldSeatNumber),
          ),
          StationReportActionInfo(
            'Nouveau siège',
            formatStationReportSeat(item.newSeatNumber),
          ),
          StationReportActionInfo(
            'Tarif actuel',
            item.oldUnitPrice.isEmpty ? '-' : item.oldUnitPrice,
          ),
          StationReportActionInfo(
            'Tarif demandé',
            item.newUnitPrice.isEmpty ? '-' : item.newUnitPrice,
          ),
          StationReportActionInfo(
            'Différence tarifaire',
            item.fareDifference.isEmpty ? '0.00' : item.fareDifference,
          ),
        ]);
      }
    }

    return StationReportActionDialogData(
      kind: StationReportRequestKind.report,
      action: action,
      reference: change.reference,
      reservationReference: change.reservationReference,
      customerLabel: change.customerName ?? 'Client',
      customerPhone: change.customerPhone,
      statusLabel: stationReportStatusLabel(change.status, change.statusLabel),
      eligibility: change.eligibility,
      infos: infos,
      consequences: _changeConsequences(action),
      warnings: _changeWarnings(action),
    );
  }

  factory StationReportActionDialogData.fromCancellation(
    StationCancellation cancellation,
    StationReportActionKind action,
  ) {
    final infos = <StationReportActionInfo>[
      StationReportActionInfo('Référence annulation', cancellation.reference),
      StationReportActionInfo('Réservation', cancellation.reservationReference),
      StationReportActionInfo('Client', cancellation.customerName ?? 'Client'),
      StationReportActionInfo('Téléphone', cancellation.customerPhone),
      StationReportActionInfo('Voyageurs', '${cancellation.travelersCount}'),
      StationReportActionInfo('Tickets', '${cancellation.ticketsCount}'),
      StationReportActionInfo('Montant', cancellation.displayAmount),
      StationReportActionInfo(
        'Éligibilité',
        stationReportEligibilityMessage(cancellation.eligibility),
      ),
    ];

    if (cancellation is StationCancellationDetail) {
      infos.addAll([
        StationReportActionInfo(
            'Tickets émis', '${cancellation.tickets.issued}'),
        StationReportActionInfo(
            'Tickets utilisés', '${cancellation.tickets.used}'),
        StationReportActionInfo(
          'Tickets à annuler',
          '${cancellation.consequences.ticketsToCancel}',
        ),
      ]);
      if (cancellation.payments.isNotEmpty) {
        final payment = cancellation.payments.first;
        infos.add(StationReportActionInfo(
          'Paiement',
          '${payment.statusLabel} - ${payment.displayAmount}',
        ));
      }
    }

    return StationReportActionDialogData(
      kind: StationReportRequestKind.cancellation,
      action: action,
      reference: cancellation.reference,
      reservationReference: cancellation.reservationReference,
      customerLabel: cancellation.customerName ?? 'Client',
      customerPhone: cancellation.customerPhone,
      statusLabel: stationReportStatusLabel(
        cancellation.status,
        cancellation.statusLabel,
      ),
      eligibility: cancellation.eligibility,
      infos: infos,
      consequences: _cancellationConsequences(action),
      warnings: _cancellationWarnings(action),
    );
  }

  String get title {
    return switch ((kind, action)) {
      (StationReportRequestKind.report, StationReportActionKind.approve) =>
        'Approuver ce report ?',
      (StationReportRequestKind.report, StationReportActionKind.reject) =>
        'Rejeter ce report ?',
      (StationReportRequestKind.report, StationReportActionKind.apply) =>
        'Appliquer ce report ?',
      (
        StationReportRequestKind.cancellation,
        StationReportActionKind.approve
      ) =>
        'Approuver cette annulation ?',
      (StationReportRequestKind.cancellation, StationReportActionKind.reject) =>
        'Rejeter cette annulation ?',
      (StationReportRequestKind.cancellation, StationReportActionKind.apply) =>
        'Appliquer cette annulation ?',
    };
  }

  String get intro {
    return switch ((kind, action)) {
      (StationReportRequestKind.report, StationReportActionKind.approve) =>
        'Cette demande sera approuvée mais ne sera pas encore appliquée.',
      (StationReportRequestKind.report, StationReportActionKind.reject) =>
        'Le rejet est définitif dans le workflow V1.',
      (StationReportRequestKind.report, StationReportActionKind.apply) =>
        'L’application mettra à jour la réservation et le ticket. Le précédent QR ne sera plus valide.',
      (
        StationReportRequestKind.cancellation,
        StationReportActionKind.approve
      ) =>
        'Cette demande sera approuvée mais la réservation ne sera annulée qu’après application.',
      (StationReportRequestKind.cancellation, StationReportActionKind.reject) =>
        'Le rejet est définitif dans le workflow V1.',
      (StationReportRequestKind.cancellation, StationReportActionKind.apply) =>
        'Cette opération annulera entièrement la réservation et ses tickets. Aucun remboursement automatique ne sera déclenché.',
    };
  }
}

class StationReportActionInfo {
  final String label;
  final String value;

  const StationReportActionInfo(this.label, this.value);
}

Future<StationReportActionDialogResult?> showStationReportActionDialog({
  required BuildContext context,
  required StationReportActionDialogData data,
}) async {
  final width = MediaQuery.sizeOf(context).width;
  final fullscreen = width < 640;

  return showDialog<StationReportActionDialogResult>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final content = _StationReportActionDialogContent(data: data);
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
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: content,
        ),
      );
    },
  );
}

class _StationReportActionDialogContent extends StatefulWidget {
  final StationReportActionDialogData data;

  const _StationReportActionDialogContent({required this.data});

  @override
  State<_StationReportActionDialogContent> createState() =>
      _StationReportActionDialogContentState();
}

class _StationReportActionDialogContentState
    extends State<_StationReportActionDialogContent> {
  final _reasonController = TextEditingController();
  String? _reasonError;

  bool get _requiresReason =>
      widget.data.action == StationReportActionKind.reject;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.data.action;
    return Column(
      children: [
        _Header(data: widget.data),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.data.intro,
                style:
                    const TextStyle(height: 1.4, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _InfoGrid(items: widget.data.infos),
              if (widget.data.consequences.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletPanel(
                  icon: Icons.rule_folder_outlined,
                  title: 'Conséquences',
                  items: widget.data.consequences,
                ),
              ],
              if (widget.data.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletPanel(
                  icon: Icons.warning_amber_outlined,
                  title: 'À vérifier avant validation',
                  items: widget.data.warnings,
                  color: _warning,
                ),
              ],
              if (_requiresReason) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  minLines: 4,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    if (_reasonError != null) {
                      setState(() => _reasonError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Motif de rejet',
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    errorText: _reasonError,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _borderColor)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              final cancel = OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              );
              final confirm = FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: action.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(action.icon, size: 18),
                label: Text(action.buttonLabelFor(widget.data.kind)),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [confirm, const SizedBox(height: 8), cancel],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [cancel, const SizedBox(width: 10), confirm],
              );
            },
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_requiresReason) {
      final reason =
          normalizeStationReportRejectionReason(_reasonController.text);
      if (reason.isEmpty) {
        setState(() => _reasonError = 'Le motif de rejet est obligatoire.');
        return;
      }
      Navigator.pop(context, StationReportActionDialogResult(reason: reason));
      return;
    }

    Navigator.pop(context, const StationReportActionDialogResult());
  }
}

class _Header extends StatelessWidget {
  final StationReportActionDialogData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.action.icon, color: data.action.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.reference} - ${data.statusLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
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

class _InfoGrid extends StatelessWidget {
  final List<StationReportActionInfo> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) =>
                  SizedBox(width: width, child: _InfoTile(item: item)))
              .toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final StationReportActionInfo item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            item.value.trim().isEmpty ? '-' : item.value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _BulletPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  const _BulletPanel({
    required this.icon,
    required this.title,
    required this.items,
    this.color = _brandPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color)),
                  Expanded(
                      child: Text(item, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _changeConsequences(StationReportActionKind action) {
  return switch (action) {
    StationReportActionKind.approve => [
        'La demande devient approuvée.',
        'Elle devra encore être appliquée pour modifier la réservation.',
        'Aucune différence tarifaire n’est prise en charge en V1.',
      ],
    StationReportActionKind.reject => [
        'La demande ne pourra plus être traitée dans ce workflow.',
        'La réservation et le ticket restent inchangés.',
      ],
    StationReportActionKind.apply => [
        'La réservation sera mise à jour vers le nouveau départ.',
        'Le ticket sera actualisé et l’ancien QR deviendra invalide.',
        'Pour Économie, aucun siège n’est attribué automatiquement.',
        'Pour Prestige, le siège cible demandé sera utilisé.',
      ],
  };
}

List<String> _changeWarnings(StationReportActionKind action) {
  if (action != StationReportActionKind.apply) return const [];
  return const [
    'Le report est irréversible dans le workflow V1.',
    'Aucun remboursement automatique n’est effectué.',
    'Aucun token QR ne sera affiché dans cet écran.',
  ];
}

List<String> _cancellationConsequences(StationReportActionKind action) {
  return switch (action) {
    StationReportActionKind.approve => [
        'La demande devient approuvée.',
        'La réservation ne sera annulée qu’après application.',
      ],
    StationReportActionKind.reject => [
        'La demande ne pourra plus être traitée dans ce workflow.',
        'La réservation et les tickets restent inchangés.',
      ],
    StationReportActionKind.apply => [
        'La réservation complète passera à annulée.',
        'Tous les tickets concernés seront annulés.',
        'Les sièges réservés seront libérés.',
        'Le paiement reste disponible pour traitement comptable futur.',
      ],
  };
}

List<String> _cancellationWarnings(StationReportActionKind action) {
  if (action != StationReportActionKind.apply) return const [];
  return const [
    'Aucun remboursement automatique ne sera déclenché.',
    'L’annulation partielle n’est pas disponible en V1.',
    'L’opération est irréversible dans le workflow V1.',
  ];
}

String _departureLabel(StationReportDepartureSummary? departure) {
  if (departure == null) return '-';
  final date = departure.departureDate ?? '-';
  final time = departure.departureTime ?? '-';
  return '${departure.routeLabel} - $date $time';
}
