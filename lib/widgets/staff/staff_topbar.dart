import 'package:flutter/material.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/models/accounts/user.dart';

class StaffTopbar extends StatelessWidget {
  final User user;
  final String title;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;

  /// Below this available width, the right-side name/role block is hidden
  /// so the title/subtitle on the left never disappears and the avatar,
  /// menu and logout button stay reachable. Fixes the P0 `RenderFlex`
  /// overflow reported in LOT 6.8A (staff_topbar.dart:75-93): that column
  /// had no `Expanded`/`Flexible` constraint at all, so a long real name
  /// pushed the row past the available width on phone-sized screens.
  static const double _identityVisibilityThreshold = 480;

  const StaffTopbar({
    super.key,
    required this.user,
    required this.title,
    required this.onLogout,
    this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.internalProfile;
    final station = profile?.station;
    final counter = profile?.counter;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: PersonnelSpacing.lg),
      decoration: BoxDecoration(
        color: PersonnelColors.surface,
        border: const Border(bottom: BorderSide(color: PersonnelColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIdentity =
              constraints.maxWidth >= _identityVisibilityThreshold;

          return Row(
            children: [
              if (onOpenMenu != null) ...[
                IconButton(
                  tooltip: 'Menu',
                  onPressed: onOpenMenu,
                  icon: const Icon(Icons.menu),
                ),
                const SizedBox(width: PersonnelSpacing.sm),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PersonnelColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _identityLine(station?.name, counter?.displayName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PersonnelColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (showIdentity) ...[
                const SizedBox(width: PersonnelSpacing.md),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          user.fullName.isEmpty ? 'Personnel' : user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.roleLabel ?? user.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PersonnelColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(width: PersonnelSpacing.sm),
              CircleAvatar(
                backgroundColor: PersonnelColors.brandPrimary,
                child: Text(
                  _initials(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: PersonnelSpacing.sm),
              IconButton(
                tooltip: 'Déconnexion',
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: PersonnelColors.danger),
              ),
            ],
          );
        },
      ),
    );
  }

  String _identityLine(String? stationName, String? counterName) {
    final parts = <String>[
      if (user.email != null && user.email!.isNotEmpty) user.email!,
      if (stationName != null && stationName.isNotEmpty) stationName,
      if (counterName != null && counterName.isNotEmpty) counterName,
    ];
    return parts.isEmpty ? 'CA TRANS' : parts.join(' • ');
  }

  String _initials(User user) {
    final first = user.firstname.isNotEmpty ? user.firstname[0] : '';
    final last = user.lastname.isNotEmpty ? user.lastname[0] : '';
    final value = '$first$last'.trim();
    return value.isEmpty ? 'CT' : value.toUpperCase();
  }
}
