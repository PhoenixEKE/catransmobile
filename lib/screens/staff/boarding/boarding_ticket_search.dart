import 'package:flutter/material.dart';

import 'package:catrans_app/models/station/station_boarding_manifest.dart';

List<StationBoardingTicket> filterBoardingTickets(
  List<StationBoardingTicket> tickets,
  String query,
) {
  final normalizedQuery = _normalizeBoardingSearch(query);
  if (normalizedQuery.isEmpty) return List.of(tickets);

  return tickets.where((ticket) {
    final searchableText = [
      ticket.displayTraveler,
      ticket.travelerFirstname,
      ticket.travelerLastname,
      ticket.travelerPhone,
      ticket.reference,
      ticket.seatNumber?.toString(),
      ticket.displaySeat,
      ticket.serviceClass,
      ticket.statusCode,
      ticket.statusLabel,
      ticket.boardingMessage,
      if (ticket.isBoarded) 'embarque valide',
      if (ticket.canBoard) 'a valider disponible',
    ].whereType<String>().join(' ');

    return _normalizeBoardingSearch(searchableText).contains(normalizedQuery);
  }).toList();
}

String _normalizeBoardingSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c');
}

class BoardingTicketSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const BoardingTicketSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: enabled
                    ? () {
                        controller.clear();
                        onChanged('');
                      }
                    : null,
                tooltip: 'Effacer la recherche',
                icon: const Icon(Icons.clear),
              ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
