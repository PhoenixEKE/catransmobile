import 'package:flutter/material.dart';

/// Shown next to a departure's status badge when it is still `scheduled`
/// ("Prévu"). The status badge alone renders in a neutral grey for that
/// code (see AdminDepartureStatusBadge._colorsFor's `default` case) and
/// doesn't make it obvious that the departure cannot be sold yet — this
/// makes that state explicit without requiring the admin to open the
/// detail view or attempt the "Ouvrir" action to find out.
class AdminDepartureNotOpenBadge extends StatelessWidget {
  const AdminDepartureNotOpenBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB54708).withValues(alpha: 0.24)),
      ),
      child: const Text(
        'Pas encore ouvert à la vente',
        style: TextStyle(
          color: Color(0xFFB54708),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
