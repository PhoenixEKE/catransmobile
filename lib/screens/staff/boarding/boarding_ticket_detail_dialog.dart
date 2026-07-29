import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/station_boarding_manifest.dart';
import 'package:catrans_app/models/station/station_departure.dart';
import 'package:catrans_app/models/station/station_ticket_validation.dart';

const _brandPurple = Color(0xFF0F056B);
const _staffBackground = Color(0xFFF5F6FA);
const _borderColor = Color(0xFFE5E7F0);
const _success = Color(0xFF157347);
const _warning = Color(0xFFB8860B);
const _danger = Color(0xFFB42318);

Future<void> showBoardingTicketDetailDialog({
  required BuildContext context,
  required StationDeparture departure,
  StationBoardingTicket? ticket,
  StationTicketValidation? validation,
  bool canValidate = false,
  bool isValidating = false,
  VoidCallback? onValidate,
}) {
  assert(ticket != null || validation != null);

  return showDialog<void>(
    context: context,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final detail = BoardingTicketDetailDialog(
        departure: departure,
        ticket: ticket,
        validation: validation,
        canValidate: canValidate,
        isValidating: isValidating,
        onValidate: onValidate,
      );

      if (size.width < 600) {
        return Dialog.fullscreen(
          backgroundColor: _staffBackground,
          child: SafeArea(child: detail),
        );
      }

      final width = size.width > 820 ? 760.0 : size.width - 40;
      final height = size.height > 820 ? 760.0 : size.height * 0.9;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(width: width, height: height, child: detail),
      );
    },
  );
}

class BoardingTicketDetailDialog extends StatelessWidget {
  final StationDeparture departure;
  final StationBoardingTicket? ticket;
  final StationTicketValidation? validation;
  final bool canValidate;
  final bool isValidating;
  final VoidCallback? onValidate;

  const BoardingTicketDetailDialog({
    super.key,
    required this.departure,
    this.ticket,
    this.validation,
    this.canValidate = false,
    this.isValidating = false,
    this.onValidate,
  }) : assert(ticket != null || validation != null);

  @override
  Widget build(BuildContext context) {
    final data = ticket != null
        ? _BoardingTicketDetailData.fromTicket(ticket!, departure)
        : _BoardingTicketDetailData.fromValidation(validation!, departure);
    final showValidationAction =
        canValidate && onValidate != null && data.canBeValidated;

    return Material(
      color: _staffBackground,
      child: Column(
        children: [
          _DetailHeader(data: data),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sections = [
                    _DetailSection(
                      icon: Icons.person_outline,
                      title: 'Voyageur',
                      rows: [
                        _DetailRow('Nom complet', data.travelerName),
                        _DetailRow('Téléphone', data.travelerPhone),
                      ],
                    ),
                    _DetailSection(
                      icon: Icons.directions_bus_outlined,
                      title: 'Voyage',
                      rows: [
                        _DetailRow('Gare de départ', data.stationName),
                        _DetailRow('Destination', data.destinationName),
                        _DetailRow('Date', data.departureDate),
                        _DetailRow('Heure', data.departureTime),
                        _DetailRow('Classe', data.serviceClass),
                        _DetailRow('Placement', data.seatLabel),
                      ],
                    ),
                    _DetailSection(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Billet',
                      rows: [
                        _DetailRow('Référence', data.ticketReference),
                        _DetailRow('Statut', data.ticketStatus),
                        if (data.reservationReference != null)
                          _DetailRow('Réservation', data.reservationReference!),
                        if (data.validatedAt != null)
                          _DetailRow('Validé le', data.validatedAt!),
                      ],
                    ),
                    _ValidationSection(data: data),
                  ];

                  if (constraints.maxWidth < 680) {
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < sections.length;
                          index++
                        ) ...[
                          sections[index],
                          if (index < sections.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  final columnWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: sections
                        .map(
                          (section) =>
                              SizedBox(width: columnWidth, child: section),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
          _DetailFooter(
            showValidationAction: showValidationAction,
            isValidating: isValidating,
            onValidate: onValidate,
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final _BoardingTicketDetailData data;

  const _DetailHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 10, 16),
      color: _brandPurple,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.travelerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                      data.ticketReference,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _DetailStatusBadge(
                      label: data.validationLabel,
                      status: data.validationStatus,
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

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_DetailRow> rows;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.rows,
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
          const SizedBox(height: 12),
          for (var index = 0; index < rows.length; index++) ...[
            rows[index],
            if (index < rows.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _ValidationSection extends StatelessWidget {
  final _BoardingTicketDetailData data;

  const _ValidationSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(data.validationStatus);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 19, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Validation',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              _DetailStatusBadge(
                label: data.validationLabel,
                status: data.validationStatus,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.validationMessage, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'Non renseigné' : value;
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

class _DetailFooter extends StatelessWidget {
  final bool showValidationAction;
  final bool isValidating;
  final VoidCallback? onValidate;

  const _DetailFooter({
    required this.showValidationAction,
    required this.isValidating,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final closeButton = OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          );
          final validateButton = FilledButton.icon(
            onPressed: isValidating
                ? null
                : () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onValidate?.call();
                    });
                  },
            icon: isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified),
            label: Text(isValidating ? 'Validation...' : 'Valider le billet'),
          );

          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showValidationAction) ...[
                  validateButton,
                  const SizedBox(height: 8),
                ],
                closeButton,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              closeButton,
              if (showValidationAction) ...[
                const SizedBox(width: 10),
                validateButton,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  final String label;
  final String status;
  final bool onDarkBackground;

  const _DetailStatusBadge({
    required this.label,
    required this.status,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDarkBackground ? Colors.white : _statusColor(status);
    return Container(
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

class _BoardingTicketDetailData {
  final String travelerName;
  final String travelerPhone;
  final String ticketReference;
  final String ticketStatus;
  final String validationStatus;
  final String validationLabel;
  final String validationMessage;
  final String stationName;
  final String destinationName;
  final String departureDate;
  final String departureTime;
  final String serviceClass;
  final String seatLabel;
  final String? reservationReference;
  final String? validatedAt;
  final bool canBeValidated;

  const _BoardingTicketDetailData({
    required this.travelerName,
    required this.travelerPhone,
    required this.ticketReference,
    required this.ticketStatus,
    required this.validationStatus,
    required this.validationLabel,
    required this.validationMessage,
    required this.stationName,
    required this.destinationName,
    required this.departureDate,
    required this.departureTime,
    required this.serviceClass,
    required this.seatLabel,
    this.reservationReference,
    this.validatedAt,
    required this.canBeValidated,
  });

  factory _BoardingTicketDetailData.fromTicket(
    StationBoardingTicket ticket,
    StationDeparture departure,
  ) {
    final isEligible =
        ticket.canBoard &&
        !ticket.isBoarded &&
        ticket.statusCode.toLowerCase() == 'issued';
    final validationStatus = ticket.isBoarded
        ? 'accepted'
        : isEligible
        ? 'pending'
        : 'rejected';
    final validationLabel = ticket.isBoarded
        ? 'Validé'
        : isEligible
        ? 'Non validé'
        : ticket.statusLabel;
    final validationMessage =
        ticket.boardingMessage ??
        (ticket.isBoarded
            ? 'Ce billet a déjà été validé pour l’embarquement.'
            : isEligible
            ? 'Ce billet est éligible à la validation pour ce départ.'
            : 'Ce billet n’est pas éligible à la validation.');

    return _BoardingTicketDetailData(
      travelerName: _notEmpty(ticket.displayTraveler, 'Voyageur non renseigné'),
      travelerPhone: _notEmpty(ticket.travelerPhone, 'Non renseigné'),
      ticketReference: _notEmpty(ticket.reference, 'Non renseignée'),
      ticketStatus: _notEmpty(ticket.statusLabel, 'Non renseigné'),
      validationStatus: validationStatus,
      validationLabel: validationLabel,
      validationMessage: validationMessage,
      stationName: _notEmpty(departure.stationName, 'Non renseignée'),
      destinationName: _notEmpty(
        ticket.destination ?? departure.destinationName,
        'Non renseignée',
      ),
      departureDate: _formatDate(
        ticket.departureDate ?? departure.departureDate,
      ),
      departureTime: _notEmpty(
        ticket.departureTime ?? departure.displayTime,
        'Non renseignée',
      ),
      serviceClass: _notEmpty(
        ticket.serviceClass ?? departure.serviceClassName,
        'Non renseignée',
      ),
      seatLabel: ticket.seatNumber == null
          ? 'Placement en gare'
          : 'Siège ${ticket.seatNumber}',
      reservationReference: _nullableNotEmpty(ticket.reservationReference),
      validatedAt: _formatOptionalDateTime(ticket.boardedAt ?? ticket.usedAt),
      canBeValidated: isEligible,
    );
  }

  factory _BoardingTicketDetailData.fromValidation(
    StationTicketValidation validation,
    StationDeparture departure,
  ) {
    return _BoardingTicketDetailData(
      travelerName: _notEmpty(
        validation.travelerFullName,
        'Voyageur non renseigné',
      ),
      travelerPhone: _notEmpty(validation.travelerPhone, 'Non renseigné'),
      ticketReference: _notEmpty(
        validation.ticketReference,
        'Référence non renseignée',
      ),
      ticketStatus: _notEmpty(validation.statusLabel, 'Non renseigné'),
      validationStatus: validation.status,
      validationLabel: _notEmpty(validation.statusLabel, 'Non renseigné'),
      validationMessage: _notEmpty(
        validation.resultMessage,
        validation.isAccepted
            ? 'Le voyageur peut embarquer sur ce départ.'
            : 'Le billet n’a pas été accepté pour ce départ.',
      ),
      stationName: _notEmpty(
        validation.stationName ?? departure.stationName,
        'Non renseignée',
      ),
      destinationName: _notEmpty(
        validation.destinationName ?? departure.destinationName,
        'Non renseignée',
      ),
      departureDate: _formatDate(
        validation.departureDate ?? departure.departureDate,
      ),
      departureTime: _notEmpty(
        validation.departureTime ?? departure.displayTime,
        'Non renseignée',
      ),
      serviceClass: _notEmpty(
        validation.serviceClassName ?? departure.serviceClassName,
        'Non renseignée',
      ),
      seatLabel: validation.seatNumber == null
          ? 'Placement en gare'
          : 'Siège ${validation.seatNumber}',
      validatedAt: _formatOptionalDateTime(validation.validatedAt),
      canBeValidated: false,
    );
  }
}

String _notEmpty(String? value, String fallback) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

String? _nullableNotEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _formatDate(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return 'Non renseignée';
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return normalized;
  return '${_twoDigits(parsed.day)}/${_twoDigits(parsed.month)}/${parsed.year}';
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
  if (normalized.contains('invalid') ||
      normalized.contains('duplicate') ||
      normalized.contains('wrong') ||
      normalized.contains('rejected') ||
      normalized.contains('refus') ||
      normalized.contains('cancel') ||
      normalized.contains('annul') ||
      normalized.contains('expired') ||
      normalized.contains('expir')) {
    return _danger;
  }
  if (normalized.contains('accepted') ||
      normalized.contains('used') ||
      normalized.contains('valid')) {
    return _success;
  }
  if (normalized.contains('pending') ||
      normalized.contains('issued') ||
      normalized.contains('non valid')) {
    return _warning;
  }
  return _brandPurple;
}
