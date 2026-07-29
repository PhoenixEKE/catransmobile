import 'package:flutter/material.dart';

/// Keeps row actions on a single, predictable line.
///
/// A [Wrap] is a poor fit for table rows because [DataTable] rows have a fixed
/// height. When the last action (typically “Désactiver”) wraps, it can overlap
/// the next row. Cards may still place this group with an [Align], while wide
/// tables naturally grow their horizontally scrollable actions column.
class StaffActionGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const StaffActionGroup({
    super.key,
    required this.children,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            children[index],
          ],
        ],
      ),
    );
  }
}
