import 'package:flutter/material.dart';

class AdminUserStatusBadge extends StatelessWidget {
  final bool isActive;

  const AdminUserStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF157347) : const Color(0xFF7A3E00);
    final background =
        isActive ? const Color(0xFFEAF6EF) : const Color(0xFFFFF3DD);
    return _Badge(
      label: isActive ? 'Actif' : 'Inactif',
      color: color,
      background: background,
    );
  }
}

class AdminUserRoleBadge extends StatelessWidget {
  final String label;

  const AdminUserRoleBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: label.isEmpty ? 'Rôle non défini' : label,
      color: const Color(0xFF0F056B),
      background: const Color(0xFFEDEBFF),
    );
  }
}

class AdminUserAssignmentBadge extends StatelessWidget {
  final bool isIncomplete;

  const AdminUserAssignmentBadge({super.key, required this.isIncomplete});

  @override
  Widget build(BuildContext context) {
    if (!isIncomplete) return const SizedBox.shrink();
    return const _Badge(
      label: 'Affectation incomplète',
      color: Color(0xFFB42318),
      background: Color(0xFFFFE9E7),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
