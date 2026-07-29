import 'package:flutter/material.dart';

class StaffScopeChip extends StatelessWidget {
  final String label;

  const StaffScopeChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFFEFF2FF),
      side: const BorderSide(color: Color(0xFFD7DDF8)),
      labelStyle: const TextStyle(
        color: Color(0xFF0F056B),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
