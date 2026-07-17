import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/station_payment_summary.dart';
import 'package:catrans_app/models/station/station_reservation_detail.dart';
import 'package:catrans_app/models/station/station_reservation_list.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBackground = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

Future<void> showStationReservationDetailDialog({
  required BuildContext context,
  required StationReservationListItem reservation,
  required Future<StationReservationDetail> Function(String reservationId)
  loadDetail,
  required bool canPrint,
  required Future<void> Function(String ticketId) onPrint,
  required Future<void> Function(String ticketId) onPdf,
}) {
  return showDialog<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final content = StationReservationDetailDialog(
        reservation: reservation,
        loadDetail: loadDetail,
        canPrint: canPrint,
        onPrint: onPrint,
        onPdf: onPdf,
      );

      if (size.width < 600) {
        return Dialog.fullscreen(
          backgroundColor: _staffBackground,
          child: SafeArea(child: content),
        );
      }

      final width = size.width > 1040 ? 980.0 : size.width - 40;
      final height = size.height > 880 ? 820.0 : size.height * 0.9;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(width: width, height: height, child: content),
      );
    },
  );
}

class StationReservationDetailDialog extends StatefulWidget {
  final StationReservationListItem reservation;
  final Future<StationReservationDetail> Function(String reservationId)
  loadDetail;
  final bool canPrint;
  final Future<void> Function(String ticketId) onPrint;
  final Future<void> Function(String ticketId) onPdf;

  const StationReservationDetailDialog({
    super.key,
    required this.reservation,
    required this.loadDetail,
    required this.canPrint,
    required this.onPrint,
    required this.onPdf,
  });

  @override
  State<StationReservationDetailDialog> createState() =>
      _StationReservationDetailDialogState();
}

class _StationReservationDetailDialogState
    extends State<StationReservationDetailDialog> {
  StationReservationDetail? _detail;
  String? _errorMessage;
  bool _isLoading = true;
  String? _printingTicketId;
  String? _openingPdfTicketId;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final detail = await widget.loadDetail(widget.reservation.id);
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

  Future<void> _showTicket(String ticketId) async {
    setState(() => _printingTicketId = ticketId);
    try {
      await widget.onPrint(ticketId);
    } catch (_) {
      // Le callback parent conserve le message métier existant.
    } finally {
      if (mounted) setState(() => _printingTicketId = null);
    }
  }

  Future<void> _openPdf(String ticketId) async {
    setState(() => _openingPdfTicketId = ticketId);
    try {
      await widget.onPdf(ticketId);
    } catch (_) {
      // Le callback parent conserve le message métier existant.
    } finally {
      if (mounted) setState(() => _openingPdfTicketId = null);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Votre session a expiré. Veuillez vous reconnecter.';
        case 403:
          return 'Vous n’êtes pas autorisé à consulter cette réservation.';
        case 404:
          return 'Cette réservation est inaccessible ou introuvable.';
        default:
          if (error.statusCode == null) {
            return 'Impossible de contacter le service. Vérifiez votre connexion.';
          }
      }
    }
    return 'Impossible de charger le détail de cette réservation.';
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final reference = detail?.reference.trim().isNotEmpty == true
        ? detail!.reference
        : widget.reservation.reference;
    final status = detail?.status.trim().isNotEmpty == true
        ? detail!.status
        : widget.reservation.status;

    return Material(
      color: _staffBackground,
      child: Column(
        children: [
          _ReservationDetailHeader(reference: reference, status: status),
          Expanded(child: _buildBody(detail)),
          const _ReservationDetailFooter(),
        ],
      ),
    );
  }

  Widget _buildBody(StationReservationDetail? detail) {
    if (_isLoading) {
      return const _ModalState(
        icon: Icons.hourglass_top,
        title: 'Chargement de la réservation…',
        message:
            'Les informations de la réservation sont en cours de chargement.',
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
        message: 'Impossible de charger le détail de cette réservation.',
        actionLabel: 'Réessayer',
        onAction: _loadDetail,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReservationSummary(detail: detail),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final client = _ClientSection(detail: detail);
              final trip = _TripSection(reservation: widget.reservation);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [client, const SizedBox(height: 14), trip],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: client),
                  const SizedBox(width: 14),
                  Expanded(child: trip),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _DetailSection(
            icon: Icons.groups_outlined,
            title: 'Voyageurs et tickets',
            child: detail.items.isEmpty
                ? const _EmptyDetailMessage(
                    message: 'Aucun voyageur associé à cette réservation.',
                  )
                : Column(
                    children: [
                      for (var index = 0; index < detail.items.length; index++)
                        _TravelerTicketCard(
                          item: detail.items[index],
                          customerName: detail.displayCustomerName,
                          customerPhone: detail.customerPhone,
                          serviceClass: widget.reservation.trip.serviceClass,
                          canPrint: widget.canPrint,
                          isLoadingPrint:
                              _printingTicketId == detail.items[index].ticketId,
                          isOpeningPdf:
                              _openingPdfTicketId ==
                              detail.items[index].ticketId,
                          onPrint: _showTicket,
                          onPdf: _openPdf,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          _PaymentSection(payments: detail.payments),
        ],
      ),
    );
  }
}

class _ReservationDetailHeader extends StatelessWidget {
  final String reference;
  final String status;

  const _ReservationDetailHeader({
    required this.reference,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 17, 10, 16),
      color: _brandPurple,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détail de la réservation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _notEmpty(reference, 'Référence non renseignée'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _StatusBadge(
                      label: _statusLabel(status),
                      status: status,
                      onDarkBackground: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer le détail',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ReservationSummary extends StatelessWidget {
  final StationReservationDetail detail;

  const _ReservationSummary({required this.detail});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _SummaryMetric(
        label: 'Référence',
        value: _notEmpty(detail.reference, '—'),
        icon: Icons.receipt_long_outlined,
      ),
      _SummaryMetric(
        label: 'Canal',
        value: _channelLabel(detail.channel),
        icon: Icons.device_hub_outlined,
      ),
      _SummaryMetric(
        label: 'Montant total',
        value: _notEmpty(detail.displayAmount, '—'),
        icon: Icons.payments_outlined,
      ),
      _SummaryMetric(
        label: 'Voyageurs',
        value: detail.items.length.toString(),
        icon: Icons.groups_outlined,
      ),
    ];

    return _DetailSection(
      icon: Icons.dashboard_outlined,
      title: 'Résumé',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760
              ? 4
              : constraints.maxWidth >= 420
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics
                .map((metric) => SizedBox(width: width, child: metric))
                .toList(),
          );
        },
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _staffBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: _brandPurple),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientSection extends StatelessWidget {
  final StationReservationDetail detail;

  const _ClientSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.person_outline,
      title: 'Client',
      child: _DetailRows(
        rows: [
          _DetailValue('Nom complet', detail.displayCustomerName),
          _DetailValue('Téléphone', detail.customerPhone),
          _DetailValue('Créée le', _formatOptionalDateTime(detail.createdAt)),
          if (detail.expiresAt != null)
            _DetailValue(
              'Expiration',
              _formatOptionalDateTime(detail.expiresAt),
            ),
        ],
      ),
    );
  }
}

class _TripSection extends StatelessWidget {
  final StationReservationListItem reservation;

  const _TripSection({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final trip = reservation.trip;
    return _DetailSection(
      icon: Icons.directions_bus_outlined,
      title: 'Voyage',
      child: _DetailRows(
        rows: [
          _DetailValue('Gare de départ', trip.departureStation),
          _DetailValue('Destination', trip.arrivalStation),
          _DetailValue(
            'Date et heure',
            _formatOptionalDateTime(trip.departureDateTime),
          ),
          _DetailValue('Classe', trip.serviceClass),
        ],
      ),
    );
  }
}

class _TravelerTicketCard extends StatelessWidget {
  final StationReservationItemDetail item;
  final String customerName;
  final String? customerPhone;
  final String? serviceClass;
  final bool canPrint;
  final bool isLoadingPrint;
  final bool isOpeningPdf;
  final Future<void> Function(String ticketId) onPrint;
  final Future<void> Function(String ticketId) onPdf;

  const _TravelerTicketCard({
    required this.item,
    required this.customerName,
    required this.customerPhone,
    required this.serviceClass,
    required this.canPrint,
    required this.isLoadingPrint,
    required this.isOpeningPdf,
    required this.onPrint,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final travelerName = item.travelerFullName.isNotEmpty
        ? item.travelerFullName
        : item.isForCustomer
        ? _notEmpty(customerName, 'Voyageur')
        : 'Voyageur non renseigné';
    final travelerPhone =
        item.travelerPhone ?? (item.isForCustomer ? customerPhone : null);
    final ticketId = item.ticketId;
    final hasTicket = ticketId != null && ticketId.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _staffBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      travelerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (travelerPhone != null &&
                        travelerPhone.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        travelerPhone,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                label: _statusLabel(item.status),
                status: item.status,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTag(
                icon: Icons.event_seat_outlined,
                value: item.seatNumber == null
                    ? 'Placement en gare'
                    : 'Siège ${item.seatNumber}',
              ),
              _InfoTag(
                icon: Icons.workspace_premium_outlined,
                value: _notEmpty(serviceClass, 'Classe non renseignée'),
              ),
              _InfoTag(
                icon: Icons.payments_outlined,
                value: _notEmpty(item.displayAmount, 'Montant non renseigné'),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (!hasTicket)
            const _EmptyDetailMessage(
              message: 'Aucun ticket généré pour ce voyageur.',
              compact: true,
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _notEmpty(item.ticketReference, 'Ticket sans référence'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                _StatusBadge(
                  label: _statusLabel(item.ticketStatus ?? ''),
                  status: item.ticketStatus ?? '',
                ),
              ],
            ),
            if (canPrint) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: isLoadingPrint ? null : () => onPrint(ticketId),
                    icon: isLoadingPrint
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Voir le ticket'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isOpeningPdf ? null : () => onPdf(ticketId),
                    icon: isOpeningPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Ouvrir le PDF'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final List<StationPaymentSummary> payments;

  const _PaymentSection({required this.payments});

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      icon: Icons.payments_outlined,
      title: 'Paiement',
      child: payments.isEmpty
          ? const _EmptyDetailMessage(
              message: 'Aucun paiement associé à cette réservation.',
            )
          : Column(
              children: [
                for (var index = 0; index < payments.length; index++) ...[
                  _PaymentRow(payment: payments[index]),
                  if (index < payments.length - 1) const Divider(height: 20),
                ],
              ],
            ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final StationPaymentSummary payment;

  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _notEmpty(payment.reference, 'Référence non renseignée'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              [
                payment.methodLabel,
                payment.providerLabel,
              ].where((part) => part.trim().isNotEmpty).join(' · '),
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        );
        final summary = Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _notEmpty(payment.displayAmount, 'Montant non renseigné'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            _StatusBadge(
              label: _notEmpty(payment.statusLabel, 'Statut non renseigné'),
              status: payment.status,
            ),
          ],
        );

        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, const SizedBox(height: 9), summary],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identity),
            const SizedBox(width: 16),
            Flexible(child: summary),
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

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 19, color: _brandPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _DetailRows extends StatelessWidget {
  final List<_DetailValue> rows;

  const _DetailRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          rows[index],
          if (index < rows.length - 1) const Divider(height: 18),
        ],
      ],
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final displayValue = _notEmpty(value, 'Non renseigné');
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                displayValue,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayValue,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoTag({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _brandPurple),
          const SizedBox(width: 6),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final String status;
  final bool onDarkBackground;

  const _StatusBadge({
    required this.label,
    required this.status,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDarkBackground ? Colors.white : _statusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onDarkBackground ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: onDarkBackground ? 0.36 : 0.28),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyDetailMessage extends StatelessWidget {
  final String message;
  final bool compact;

  const _EmptyDetailMessage({required this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: _staffBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 34, color: _brandPurple),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _brandPurple,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationDetailFooter extends StatelessWidget {
  const _ReservationDetailFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ),
    );
  }
}

String _notEmpty(String? value, String fallback) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

String _statusLabel(String status) {
  final normalized = status.toLowerCase();
  if (normalized == 'pending_payment') return 'En attente de paiement';
  if (normalized == 'confirmed') return 'Confirmée';
  if (normalized == 'cancelled' || normalized == 'canceled') return 'Annulée';
  if (normalized == 'expired') return 'Expirée';
  if (normalized == 'failed') return 'Échouée';
  if (normalized == 'issued') return 'Émis';
  if (normalized == 'used') return 'Utilisé';
  return status.trim().isEmpty ? 'Non renseigné' : status;
}

String _channelLabel(String channel) {
  final normalized = channel.toLowerCase();
  if (normalized == 'customer_app') return 'Application client';
  if (normalized == 'station_counter') return 'Guichet gare';
  if (normalized == 'admin_portal') return 'Portail administration';
  return _notEmpty(channel, 'Non renseigné');
}

String? _formatOptionalDateTime(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year} à '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') ||
      normalized.contains('cancel') ||
      normalized.contains('expired') ||
      normalized.contains('rejected')) {
    return _danger;
  }
  if (normalized.contains('pending') ||
      normalized.contains('processing') ||
      normalized.contains('initiated') ||
      normalized.contains('issued')) {
    return _warning;
  }
  if (normalized.contains('confirm') ||
      normalized.contains('success') ||
      normalized.contains('paid') ||
      normalized.contains('used')) {
    return _success;
  }
  return _brandPurple;
}
