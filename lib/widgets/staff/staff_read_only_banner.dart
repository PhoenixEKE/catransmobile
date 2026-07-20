import 'package:flutter/material.dart';

class StaffReadOnlyBanner extends StatelessWidget {
  final bool isReadOnly;
  final String message;

  const StaffReadOnlyBanner({
    super.key,
    required this.isReadOnly,
    this.message = 'Accès en lecture seule',
  });

  @override
  Widget build(BuildContext context) {
    if (!isReadOnly) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFD807).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFFEFD807).withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 18, color: Color(0xFF5E5200)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5E5200),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
