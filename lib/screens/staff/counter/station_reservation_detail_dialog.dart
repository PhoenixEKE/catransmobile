import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/booking/seat_map_response.dart';
import 'package:catrans_app/models/booking/seat_map_seat.dart';
import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';
import 'package:catrans_app/models/station/station_payment_summary.dart';
import 'package:catrans_app/models/station/station_reservation_detail.dart';
import 'package:catrans_app/models/station/station_reservation_list.dart';
import 'package:catrans_app/services/api/booking_api_service.dart';
import 'package:catrans_app/services/api/station_operational_departures_api_service.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBackground = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

typedef StationReservationItemEditCallback
    = Future<StationReservationItemEditResponse> Function({
  required String reservationId,
  required String itemId,
  String? travelerLastname,
  String? travelerFirstname,
  String? travelerPhone,
  String? newDepartureId,
  String? newDepartureSeatId,
  String? notes,
});

typedef StationTicketSuspendCallback = Future<StationTicketActionResponse>
    Function({
  required String reservationId,
  required String itemId,
  required DateTime suspendedUntil,
  String? notes,
});

typedef StationTicketReactivateCallback = Future<StationTicketActionResponse>
    Function({
  required String reservationId,
  required String itemId,
});

Future<void> showStationReservationDetailDialog({
  required BuildContext context,
  required StationReservationListItem reservation,
  required Future<StationReservationDetail> Function(String reservationId)
      loadDetail,
  required StationReservationItemEditCallback editItem,
  required StationTicketSuspendCallback suspendTicket,
  required StationTicketReactivateCallback reactivateTicket,
  required bool canEditItems,
  String? stationId,
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
        editItem: editItem,
        suspendTicket: suspendTicket,
        reactivateTicket: reactivateTicket,
        canEditItems: canEditItems,
        stationId: stationId,
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
  final StationReservationItemEditCallback editItem;
  final StationTicketSuspendCallback suspendTicket;
  final StationTicketReactivateCallback reactivateTicket;
  final bool canEditItems;
  final String? stationId;
  final bool canPrint;
  final Future<void> Function(String ticketId) onPrint;
  final Future<void> Function(String ticketId) onPdf;

  const StationReservationDetailDialog({
    super.key,
    required this.reservation,
    required this.loadDetail,
    required this.editItem,
    required this.suspendTicket,
    required this.reactivateTicket,
    required this.canEditItems,
    this.stationId,
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
  String? _editingItemId;
  String? _ticketActionItemId;

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

  Future<void> _editTraveler(StationReservationItemDetail item) async {
    setState(() => _editingItemId = item.id);
    try {
      final result = await showDialog<StationReservationItemEditResponse>(
        context: context,
        useSafeArea: true,
        builder: (context) => _TravelerEditDialog(
          reservationId: widget.reservation.id,
          item: item,
          stationId: widget.stationId,
          editItem: widget.editItem,
        ),
      );
      if (!mounted || result == null) return;
      setState(() => _detail = result.reservation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Voyageur modifié.' : result.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _editingItemId = null);
    }
  }

  Future<void> _suspendTicket(StationReservationItemDetail item) async {
    final suspendedUntil = await showDialog<DateTime>(
      context: context,
      builder: (context) => const _TicketSuspendDialog(),
    );
    if (!mounted || suspendedUntil == null) return;

    setState(() => _ticketActionItemId = item.id);
    try {
      final result = await widget.suspendTicket(
        reservationId: widget.reservation.id,
        itemId: item.id,
        suspendedUntil: suspendedUntil,
        notes: 'Suspension ticket depuis le portail gare/admin.',
      );
      if (!mounted) return;
      setState(() => _detail = result.reservation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Ticket suspendu.' : result.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    } finally {
      if (mounted) setState(() => _ticketActionItemId = null);
    }
  }

  Future<void> _reactivateTicket(StationReservationItemDetail item) async {
    setState(() => _ticketActionItemId = item.id);
    try {
      final result = await widget.reactivateTicket(
        reservationId: widget.reservation.id,
        itemId: item.id,
      );
      if (!mounted) return;
      setState(() => _detail = result.reservation);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Ticket réactivé.' : result.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFromError(error))),
      );
    } finally {
      if (mounted) setState(() => _ticketActionItemId = null);
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
                          canEdit: widget.canEditItems,
                          isLoadingPrint:
                              _printingTicketId == detail.items[index].ticketId,
                          isOpeningPdf: _openingPdfTicketId ==
                              detail.items[index].ticketId,
                          isEditing: _editingItemId == detail.items[index].id,
                          isTicketAction:
                              _ticketActionItemId == detail.items[index].id,
                          onPrint: _showTicket,
                          onPdf: _openPdf,
                          onEdit: _editTraveler,
                          onSuspend: _suspendTicket,
                          onReactivate: _reactivateTicket,
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
  final bool canEdit;
  final bool isLoadingPrint;
  final bool isOpeningPdf;
  final bool isEditing;
  final bool isTicketAction;
  final Future<void> Function(String ticketId) onPrint;
  final Future<void> Function(String ticketId) onPdf;
  final Future<void> Function(StationReservationItemDetail item) onEdit;
  final Future<void> Function(StationReservationItemDetail item) onSuspend;
  final Future<void> Function(StationReservationItemDetail item) onReactivate;

  const _TravelerTicketCard({
    required this.item,
    required this.customerName,
    required this.customerPhone,
    required this.serviceClass,
    required this.canPrint,
    required this.canEdit,
    required this.isLoadingPrint,
    required this.isOpeningPdf,
    required this.isEditing,
    required this.isTicketAction,
    required this.onPrint,
    required this.onPdf,
    required this.onEdit,
    required this.onSuspend,
    required this.onReactivate,
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
                value: _notEmpty(
                  item.serviceClassName ?? serviceClass,
                  'Classe non renseignée',
                ),
              ),
              _InfoTag(
                icon: Icons.route_outlined,
                value: item.tripLabel,
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
                if (item.isSuspended)
                  _StatusBadge(
                    label:
                        'Suspendu jusqu’au ${_formatOptionalDateTime(item.ticketSuspendedUntil)}',
                    status: 'suspended',
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
            if (canEdit) ...[
              const SizedBox(height: 10),
              if (item.canEdit || item.canSuspend || item.canReactivate)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.canEdit)
                      FilledButton.icon(
                        onPressed: isEditing ? null : () => onEdit(item),
                        icon: isEditing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Modifier ce voyageur'),
                      ),
                    if (item.canSuspend)
                      OutlinedButton.icon(
                        onPressed:
                            isTicketAction ? null : () => onSuspend(item),
                        icon: isTicketAction
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.pause_circle_outline, size: 18),
                        label: const Text('Suspendre'),
                      ),
                    if (item.canReactivate)
                      OutlinedButton.icon(
                        onPressed:
                            isTicketAction ? null : () => onReactivate(item),
                        icon: isTicketAction
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Réactiver'),
                      ),
                  ],
                )
              else
                const _EmptyDetailMessage(
                  message:
                      'Ce voyageur a déjà embarqué ou son ticket n’est plus modifiable.',
                  compact: true,
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

class _TravelerEditDialog extends StatefulWidget {
  final String reservationId;
  final StationReservationItemDetail item;
  final String? stationId;
  final StationReservationItemEditCallback editItem;

  const _TravelerEditDialog({
    required this.reservationId,
    required this.item,
    required this.stationId,
    required this.editItem,
  });

  @override
  State<_TravelerEditDialog> createState() => _TravelerEditDialogState();
}

class _TravelerEditDialogState extends State<_TravelerEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lastnameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _departuresApi = StationOperationalDeparturesApiService();
  final _bookingApi = BookingApiService();

  DateTime? _departureDate;
  bool _isLoadingDepartures = false;
  bool _isLoadingSeats = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedDepartureId;
  String? _selectedDepartureSeatId;
  StationOperationalDeparturesResponse? _departuresResponse;
  SeatMapResponse? _seatMap;

  @override
  void initState() {
    super.initState();
    _lastnameController.text = widget.item.travelerLastname ?? '';
    _firstnameController.text = widget.item.travelerFirstname ?? '';
    _phoneController.text = widget.item.travelerPhone ?? '';
    _selectedDepartureId = widget.item.departure;
    _departureDate = DateTime.tryParse(widget.item.departureDate ?? '');
    if (widget.item.usesManualSeat) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSeatMap());
    }
  }

  @override
  void dispose() {
    _lastnameController.dispose();
    _firstnameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final content = AlertDialog(
      title: const Text('Modifier le voyageur'),
      content: SizedBox(
        width: size.width > 760 ? 680 : size.width - 48,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTravelerFields(),
                const SizedBox(height: 16),
                _buildDepartureSection(),
                const SizedBox(height: 16),
                _buildSeatSection(),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note audit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: _danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Appliquer'),
        ),
      ],
    );

    if (size.width < 620) {
      return Dialog.fullscreen(
        backgroundColor: _staffBackground,
        child: SafeArea(child: content),
      );
    }
    return content;
  }

  Widget _buildTravelerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voyageur',
          style: TextStyle(fontWeight: FontWeight.w800, color: _brandPurple),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final fields = [
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nom requis' : null,
              ),
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Prénom requis'
                    : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ];
            if (compact) {
              return Column(
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    fields[i],
                    if (i < fields.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 10),
                Expanded(child: fields[1]),
                const SizedBox(width: 10),
                Expanded(child: fields[2]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDepartureSection() {
    final departures = _departuresResponse?.results ?? const [];
    final selectedDeparture =
        _findDepartureById(departures, _selectedDepartureId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Départ',
          style: TextStyle(fontWeight: FontWeight.w800, color: _brandPurple),
        ),
        const SizedBox(height: 8),
        Text(
          [
            widget.item.tripLabel,
            widget.item.departureDate,
            widget.item.departureTime,
          ].where((part) => part != null && part.trim().isNotEmpty).join(' · '),
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isLoadingDepartures ? null : _pickDepartureDate,
              icon: const Icon(Icons.event),
              label: Text(
                _departureDate == null
                    ? 'Date cible'
                    : _formatSimpleDate(_departureDate!),
              ),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _loadDepartures(),
              ),
            ),
            FilledButton.icon(
              onPressed: _isLoadingDepartures ? null : _loadDepartures,
              icon: _isLoadingDepartures
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Chercher'),
            ),
          ],
        ),
        if (departures.isNotEmpty) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue:
                selectedDeparture == null ? null : _selectedDepartureId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau départ (classe possible différente)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: departures
                .map(
                  (departure) => DropdownMenuItem<String>(
                    value: departure.id,
                    child: Text(
                      '${_formatOptionalDate(departure.departureDate)} · '
                      '${departure.displayTime} · ${departure.displayRoute} · '
                      '${departure.displayServiceClass}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDepartureId = value;
                _selectedDepartureSeatId = null;
                _seatMap = null;
              });
              _loadSeatMap();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSeatSection() {
    final selectedDepartureId = _selectedDepartureId;
    final availableSeats = (_seatMap?.seats ?? const <SeatMapSeat>[])
        .where((seat) => seat.isAvailableForSelection)
        .toList();
    final seatSelectionAllowed = _seatMap?.seatSelection.allowed == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Siège',
          style: TextStyle(fontWeight: FontWeight.w800, color: _brandPurple),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.seatNumber == null
              ? 'Placement en gare actuellement.'
              : 'Siège actuel ${widget.item.seatNumber}.',
          style: const TextStyle(color: Colors.black54),
        ),
        if (selectedDepartureId != null) ...[
          const SizedBox(height: 10),
          if (_isLoadingSeats)
            const LinearProgressIndicator()
          else if (_seatMap == null)
            OutlinedButton.icon(
              onPressed: _loadSeatMap,
              icon: const Icon(Icons.event_seat_outlined),
              label: const Text('Charger les sièges'),
            )
          else if (!seatSelectionAllowed)
            const _EmptyDetailMessage(
              message:
                  'Cette classe utilise le placement en gare. Aucun siège manuel requis.',
              compact: true,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartureSeatId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau siège',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: availableSeats
                  .map(
                    (seat) => DropdownMenuItem<String>(
                      value: seat.id,
                      child: Text('Siège ${seat.displayLabel}'),
                    ),
                  )
                  .toList(),
              onChanged: availableSeats.isEmpty
                  ? null
                  : (value) => setState(() => _selectedDepartureSeatId = value),
            ),
        ],
      ],
    );
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _departureDate ?? now,
    );
    if (selected != null && mounted) {
      setState(() => _departureDate = selected);
    }
  }

  Future<void> _loadDepartures() async {
    setState(() {
      _isLoadingDepartures = true;
      _errorMessage = null;
    });
    try {
      final response = await _departuresApi.getOperationalDepartures(
        date: _departureDate,
        statuses: const ['open'],
        search: _searchController.text,
        stationId: widget.stationId,
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _departuresResponse = response;
        if (response.results.isNotEmpty) {
          _selectedDepartureId = response.results.first.id;
          _selectedDepartureSeatId = null;
          _seatMap = null;
        }
      });
      if (response.results.isNotEmpty) {
        await _loadSeatMap();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoadingDepartures = false);
    }
  }

  Future<void> _loadSeatMap() async {
    final departureId = _selectedDepartureId;
    if (departureId == null || departureId.isEmpty) return;
    setState(() {
      _isLoadingSeats = true;
      _errorMessage = null;
    });
    try {
      final seatMap = await _bookingApi.getSeatMap(departureId: departureId);
      if (!mounted) return;
      setState(() => _seatMap = seatMap);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isLoadingSeats = false);
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final lastname = _lastnameController.text.trim();
    final firstname = _firstnameController.text.trim();
    final phone = _phoneController.text.trim();
    final travelerChanged = lastname != (widget.item.travelerLastname ?? '') ||
        firstname != (widget.item.travelerFirstname ?? '') ||
        phone != (widget.item.travelerPhone ?? '');
    final departureChanged = _selectedDepartureId != null &&
        _selectedDepartureId != widget.item.departure;
    final seatChanged = _selectedDepartureSeatId != null &&
        _selectedDepartureSeatId != widget.item.departureSeat;

    if (!travelerChanged && !departureChanged && !seatChanged) {
      setState(() => _errorMessage = 'Aucune modification à appliquer.');
      return;
    }

    if (_seatMap?.seatSelection.allowed == true &&
        departureChanged &&
        _selectedDepartureSeatId == null) {
      setState(() => _errorMessage = 'Choisissez un siège pour ce départ.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.editItem(
        reservationId: widget.reservationId,
        itemId: widget.item.id,
        travelerLastname: travelerChanged ? lastname : null,
        travelerFirstname: travelerChanged ? firstname : null,
        travelerPhone: travelerChanged ? phone : null,
        newDepartureId: departureChanged ? _selectedDepartureId : null,
        newDepartureSeatId: seatChanged ? _selectedDepartureSeatId : null,
        notes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFromError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) return error.message;
    return 'Impossible d’appliquer la modification.';
  }
}

class _TicketSuspendDialog extends StatefulWidget {
  const _TicketSuspendDialog();

  @override
  State<_TicketSuspendDialog> createState() => _TicketSuspendDialogState();
}

class _TicketSuspendDialogState extends State<_TicketSuspendDialog> {
  DateTime _suspendedUntil = DateTime.now().add(const Duration(hours: 2));
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suspendre le ticket'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('30 min'),
                  selected: false,
                  onSelected: (_) => _setDuration(const Duration(minutes: 30)),
                ),
                ChoiceChip(
                  label: const Text('2 h'),
                  selected: false,
                  onSelected: (_) => _setDuration(const Duration(hours: 2)),
                ),
                ChoiceChip(
                  label: const Text('24 h'),
                  selected: false,
                  onSelected: (_) => _setDuration(const Duration(hours: 24)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_formatOptionalDateTime(_suspendedUntil) ?? '-'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: _danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.pause_circle_outline),
          label: const Text('Suspendre'),
        ),
      ],
    );
  }

  void _setDuration(Duration duration) {
    setState(() {
      _suspendedUntil = DateTime.now().add(duration);
      _errorMessage = null;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _suspendedUntil,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_suspendedUntil),
    );
    if (time == null || !mounted) return;

    setState(() {
      _suspendedUntil = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _errorMessage = null;
    });
  }

  void _confirm() {
    if (!_suspendedUntil.isAfter(DateTime.now())) {
      setState(() => _errorMessage = 'Choisissez une date future.');
      return;
    }
    Navigator.pop(context, _suspendedUntil);
  }
}

StationOperationalDeparture? _findDepartureById(
  List<StationOperationalDeparture> departures,
  String? departureId,
) {
  if (departureId == null) return null;
  for (final departure in departures) {
    if (departure.id == departureId) return departure;
  }
  return null;
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
  if (normalized == 'suspended') return 'Suspendu';
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

String _formatSimpleDate(DateTime value) {
  return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
}

String _formatOptionalDate(DateTime? value) {
  if (value == null) return '-';
  return _formatSimpleDate(value);
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
      normalized.contains('suspended') ||
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
