import 'package:flutter/material.dart';

class StaffPaginationControls extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const StaffPaginationControls({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: 'Page précédente',
          onPressed: hasPrevious ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Page suivante',
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
