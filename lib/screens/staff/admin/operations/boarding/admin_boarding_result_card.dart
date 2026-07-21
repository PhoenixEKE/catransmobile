import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/station_ticket_validation.dart';
import 'package:catrans_app/screens/staff/boarding/boarding_qr_scanner_helpers.dart';

class AdminBoardingResultCard extends StatelessWidget {
  final StationTicketValidation validation;
  final VoidCallback onClear;

  const AdminBoardingResultCard({
    super.key,
    required this.validation,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = presentationForValidation(validation);
    final color = presentation.isSuccess
        ? const Color(0xFF157347)
        : const Color(0xFFB42318);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(presentation.icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(presentation.message),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Effacer',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Chip(label: 'Ticket', value: validation.ticketReference),
              _Chip(label: 'Voyageur', value: validation.travelerFullName),
              _Chip(label: 'Siège', value: validation.displaySeat),
              _Chip(label: 'Classe', value: validation.serviceClassName),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? value;

  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayed = value == null || value!.trim().isEmpty ? '-' : value!;
    return Chip(label: Text('$label : $displayed'));
  }
}
