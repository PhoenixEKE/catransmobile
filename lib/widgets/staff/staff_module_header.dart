import 'package:flutter/material.dart';

import 'package:catrans_app/core/design/personnel_design.dart';

class StaffModuleHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  const StaffModuleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < PersonnelBreakpoints.mobile;
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PersonnelColors.brandPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(PersonnelRadius.sm),
              ),
              child: Icon(icon, color: PersonnelColors.brandPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: PersonnelColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PersonnelColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (trailing == null) return content;

        // P0 fix (LOT 6.8A / 6.8B1): the trailing slot (e.g. a counter
        // badge, or a future primary action button) must never be dropped
        // from the render tree. Below the breakpoint it is stacked full
        // width under the title/description instead of being discarded.
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: PersonnelSpacing.md),
              trailing!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: 16),
            trailing!,
          ],
        );
      },
    );
  }
}
