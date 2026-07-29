import 'package:flutter/material.dart';

class AdminDepartureStatusBadge extends StatelessWidget {
  final String code;
  final String label;

  const AdminDepartureStatusBadge({
    super.key,
    required this.code,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.24)),
      ),
      child: Text(
        label.isEmpty ? code : label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(String status) {
    switch (status) {
      case 'open':
        return const _BadgeColors(Color(0xFFEAF7EF), Color(0xFF157347));
      case 'closed':
        return const _BadgeColors(Color(0xFFFFF4E5), Color(0xFFB54708));
      case 'departed':
        return const _BadgeColors(Color(0xFFEFF4FF), Color(0xFF175CD3));
      case 'cancelled':
        return const _BadgeColors(Color(0xFFFFF2F2), Color(0xFFB42318));
      default:
        return const _BadgeColors(Color(0xFFF7F8FC), Color(0xFF344054));
    }
  }
}

class _BadgeColors {
  final Color background;
  final Color foreground;

  const _BadgeColors(this.background, this.foreground);
}
