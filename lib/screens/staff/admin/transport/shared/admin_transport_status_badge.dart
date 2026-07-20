import 'package:flutter/material.dart';

class AdminTransportStatusBadge extends StatelessWidget {
  final bool isActive;

  const AdminTransportStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF157347) : const Color(0xFFB42318);
    final background =
        isActive ? const Color(0xFFEAF7EF) : const Color(0xFFFFF2F2);
    final label = isActive ? 'Actif' : 'Inactif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
