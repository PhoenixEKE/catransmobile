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
        // Le header passe en disposition verticale dès que la largeur
        // disponible devient insuffisante pour afficher correctement
        // le contenu principal et les actions.
        //
        // Le seuil de 960 px corrige notamment le cas tablette à 752 px
        // observé dans les tests du dashboard.
        final compact = constraints.maxWidth < 960;

        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PersonnelColors.brandPrimary.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(
                  PersonnelRadius.sm,
                ),
              ),
              child: Icon(
                icon,
                color: PersonnelColors.brandPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

        final trailingWidget = trailing;

        if (trailingWidget == null) {
          return content;
        }

        // En mode compact, les actions restent visibles mais passent
        // sous le titre et la description.
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(
                height: PersonnelSpacing.md,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: trailingWidget,
              ),
            ],
          );
        }

        // Sur grand écran, le contenu principal occupe l'espace disponible
        // et le trailing reçoit une largeur contrainte afin d'éviter
        // tout RenderFlex overflow.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: content,
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: trailingWidget,
              ),
            ),
          ],
        );
      },
    );
  }
}
