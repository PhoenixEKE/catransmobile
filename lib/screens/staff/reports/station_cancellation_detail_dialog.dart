import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/reports/station_cancellation.dart';
import 'package:catrans_app/models/station/reports/station_cancellation_detail.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/screens/staff/reports/station_reports_ui_helpers.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBg = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

Future<void> showStationCancellationDetailDialog({
  required BuildContext context,
  required StationCancellation cancellation,
  required Future<StationCancellationDetail> Function(String cancellationId)
      loadDetail,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = StationCancellationDetailDialog(
        cancellation: cancellation,
        loadDetail: loadDetail,
      );

      if (size.width < 640) {
        return Dialog.fullscreen(
          backgroundColor: _staffBg,
          child: SafeArea(child: content),
        );
      }

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: size.width > 1040 ? 980 : size.width - 44,
          height: size.height > 880 ? 820 : size.height * 0.9,
          child: content,
        ),
      );
    },
  );
}

class StationCancellationDetailDialog extends StatefulWidget {
  final StationCancellation cancellation;
  final Future<StationCancellationDetail> Function(String cancellationId)
      loadDetail;

  const StationCancellationDetailDialog({
    super.key,
    required this.cancellation,
    required this.loadDetail,
  });

  @override
  State<StationCancellationDetailDialog> createState() =>
      _StationCancellationDetailDialogState();
}

class _StationCancellationDetailDialogState
    extends State<StationCancellationDetailDialog> {
  StationCancellationDetail? _detail;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget.loadDetail(widget.cancellation.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _errorMessage = _messageFromError(error);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’êtes pas autorisé à consulter cette annulation.';
        case 404:
          return 'Cette demande d’annulation n’est plus accessible.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
    }
    return 'Impossible de charger le détail de cette annulation.';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final reference = detail?.reference.trim().isNotEmpty == true
        ? detail!.reference
        : widget.cancellation.reference;
    final status = detail?.status ?? widget.cancellation.status;
    final statusLabel = stationReportStatusLabel(
      status,
      detail?.statusLabel ?? widget.cancellation.statusLabel,
    );

    return Material(
      color: _staffBg,
      child: Column(
        children: [
          _DialogHeader(
            reference: reference,
            status: status,
            statusLabel: statusLabel,
            channelLabel:
                detail?.channelLabel ?? widget.cancellation.channelLabel,
            requestedAt: detail?.requestedAt ?? widget.cancellation.requestedAt,
            eligibility: detail?.eligibility ?? widget.cancellation.eligibility,
          ),
          Expanded(child: _buildBody(detail)),
          const _DialogFooter(),
        ],
      ),
    );
  }

  Widget _buildBody(StationCancellationDetail? detail) {
    if (_isLoading) {
      return const _ModalState(
        icon: Icons.hourglass_top,
        title: 'Chargement de l’annulation…',
        message: 'Le détail de la demande est en cours de chargement.',
        showProgress: true,
      );
    }

    if (_errorMessage != null) {
      return _ModalState(
        icon: Icons.error_outline,
        title: 'Détail indisponible',
        message: _errorMessage!,
        actionLabel: 'Réessayer',
        onAction: _loadDetail,
      );
    }

    if (detail == null) {
      return _ModalState(
        icon: Icons.inbox_outlined,
        title: 'Détail indisponible',
        message: 'Impossible de charger le détail de cette annulation.',
        actionLabel: 'Réessayer',
        onAction: _loadDetail,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 640 ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EligibilityBanner(eligibility: detail.eligibility),
          const SizedBox(height: 14),
          _ResponsivePair(
            left: _ReservationSection(detail: detail),
            right: _TicketsSection(detail: detail),
          ),
          const SizedBox(height: 14),
          _PaymentsSection(detail: detail),
          const SizedBox(height: 14),
          _ResponsivePair(
            left: _ConsequencesSection(detail: detail),
            right: _ReasonTimelineSection(detail: detail),
          ),
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String reference;
  final String status;
  final String statusLabel;
  final String channelLabel;
  final DateTime? requestedAt;
  final StationReportEligibility eligibility;

  const _DialogHeader({
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.channelLabel,
    required this.requestedAt,
    required this.eligibility,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _brandPurple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_return, color: _brandPurple),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _brandPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$channelLabel • Demandé le ${formatStationReportDateTime(requestedAt)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                        label: statusLabel,
                        color: _toneColor(stationReportStatusTone(status))),
                    _Badge(
                        label: eligibility.isEligible
                            ? 'Éligible'
                            : 'Non éligible',
                        color: eligibility.isEligible ? _success : _warning),
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

class _ReservationSection extends StatelessWidget {
  final StationCancellationDetail detail;

  const _ReservationSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final reservation = detail.reservation;
    return _DetailSection(
      icon: Icons.confirmation_number_outlined,
      title: 'Réservation',
      child: Column(
        children: [
          _InfoRow('Référence',
              reservation?.reference ?? detail.reservationReference),
          _InfoRow('Client', detail.customerName ?? '-'),
          _InfoRow('Téléphone', detail.customerPhone),
          _InfoRow(
              'Statut', reservation?.statusLabel ?? reservation?.status ?? '-'),
          _InfoRow('Montant',
              formatStationReportAmount(detail.totalAmount, detail.currency)),
        ],
      ),
    );
  }
}

class _TicketsSection extends StatelessWidget {
  final StationCancellationDetail detail;

  const _TicketsSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.airplane_ticket_outlined,
      title: 'Voyageurs et tickets',
      child: Column(
        children: [
          _InfoRow('Voyageurs', detail.travelersCount.toString()),
          _InfoRow('Tickets', detail.ticketsCount.toString()),
          _InfoRow('Tickets émis', detail.tickets.issued.toString()),
          _InfoRow('Tickets utilisés', detail.tickets.used.toString()),
          _InfoRow('Tickets annulés', detail.tickets.cancelled.toString()),
        ],
      ),
    );
  }
}

class _PaymentsSection extends StatelessWidget {
  final StationCancellationDetail detail;

  const _PaymentsSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.payments_outlined,
      title: 'Paiements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WarningText(
              'Aucun remboursement automatique n’est déclenché dans cette version.'),
          const SizedBox(height: 10),
          if (detail.payments.isEmpty)
            const Text('Aucun paiement associé.',
                style: TextStyle(color: Colors.black54))
          else
            for (final payment in detail.payments)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _MiniInfo(label: 'Référence', value: payment.reference),
                    _MiniInfo(
                        label: 'Statut',
                        value: payment.statusLabel.isEmpty
                            ? payment.status
                            : payment.statusLabel),
                    _MiniInfo(label: 'Montant', value: payment.displayAmount),
                    _MiniInfo(label: 'Provider', value: payment.provider),
                    _MiniInfo(
                        label: 'Payé le',
                        value: formatStationReportDateTime(payment.paidAt)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ConsequencesSection extends StatelessWidget {
  final StationCancellationDetail detail;

  const _ConsequencesSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final consequences = detail.consequences;
    return _DetailSection(
      icon: Icons.fact_check_outlined,
      title: 'Conséquences',
      child: Column(
        children: [
          _InfoRow(
              'Portée',
              consequences.cancellationScope == 'full_reservation'
                  ? 'Annulation complète'
                  : _dash(consequences.cancellationScope)),
          _InfoRow(
              'Tickets concernés', consequences.ticketsToCancel.toString()),
          _RuleRow('Remboursement automatique désactivé',
              !consequences.refundAutomatic),
          _RuleRow('Annulation partielle non supportée',
              !consequences.partialCancellationSupported),
          _RuleRow('Ajustement tarifaire non supporté',
              !consequences.fareAdjustmentSupported),
        ],
      ),
    );
  }
}

class _ReasonTimelineSection extends StatelessWidget {
  final StationCancellationDetail detail;

  const _ReasonTimelineSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.timeline_outlined,
      title: 'Motifs et acteurs',
      child: Column(
        children: [
          _InfoRow('Motif', _dash(detail.reason)),
          if (detail.rejectionReason != null)
            _InfoRow('Motif de rejet', detail.rejectionReason!),
          const Divider(height: 22),
          _TimelineRow(
              'Demandé par',
              _actorName(detail.requestedBy, detail.requestedByName),
              detail.requestedAt),
          _TimelineRow(
              'Examiné par',
              _actorName(detail.reviewedBy, detail.reviewedByName),
              detail.reviewedAt),
          _TimelineRow(
              'Appliqué par',
              _actorName(detail.appliedBy, detail.appliedByName),
              detail.appliedAt),
          if (detail.cancelledAt != null)
            _TimelineRow('Annulé', null, detail.cancelledAt),
        ],
      ),
    );
  }
}

class _EligibilityBanner extends StatelessWidget {
  final StationReportEligibility eligibility;

  const _EligibilityBanner({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final eligible = eligibility.isEligible;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (eligible ? _success : _warning).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: (eligible ? _success : _warning).withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              eligible
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: eligible ? _success : _warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eligible ? 'Éligibilité confirmée' : 'Éligibilité bloquée',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(stationReportEligibilityMessage(eligibility)),
                if (!eligible && eligibility.blockingCode != null) ...[
                  const SizedBox(height: 3),
                  Text('Code diagnostic : ${eligibility.blockingCode}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsivePair({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 14), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right)
          ],
        );
      },
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailSection(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _brandPurple),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: _brandPurple))),
            ],
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

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String? actor;
  final DateTime? at;

  const _TimelineRow(this.label, this.actor, this.at);

  @override
  Widget build(BuildContext context) {
    final text = actor == null || actor!.trim().isEmpty ? '-' : actor!;
    return _InfoRow(label, '$text • ${formatStationReportDateTime(at)}');
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool active;

  const _RuleRow(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle_outline : Icons.info_outline,
              size: 18, color: active ? _success : _warning),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WarningText extends StatelessWidget {
  final String text;

  const _WarningText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: _warning),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black87))),
      ],
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _ModalState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ModalState({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: _brandPurple),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            if (showProgress) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor))),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ),
    );
  }
}

String _actorName(StationReportActor? actor, String? fallback) {
  final name = actor?.fullName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final email = actor?.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  final fallbackName = fallback?.trim();
  if (fallbackName != null && fallbackName.isNotEmpty) return fallbackName;
  return '-';
}

String _dash(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? '-' : text;
}

Color _toneColor(String tone) {
  return switch (tone) {
    'success' => _success,
    'warning' => _warning,
    'danger' => _danger,
    'info' => _brandPurple,
    _ => Colors.blueGrey,
  };
}
