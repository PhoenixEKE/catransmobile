import 'package:flutter/material.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/shell/staff_menu_item.dart';

class StaffSidebar extends StatelessWidget {
  final User user;
  final List<StaffMenuItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const StaffSidebar({
    super.key,
    required this.user,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.internalProfile;
    final locationLine = _locationLine(
      profile?.station?.name,
      profile?.counter?.displayName,
    );

    return Container(
      width: 280,
      color: PersonnelColors.brandPrimary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(PersonnelSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      height: 34,
                      width: 34,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 28,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CA TRANS\nPersonnel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: PersonnelSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(PersonnelSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(PersonnelRadius.sm),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty
                          ? 'Personnel CA TRANS'
                          : user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.roleLabel ??
                          profile?.role.name ??
                          'Rôle interne',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (locationLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        locationLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: PersonnelSpacing.lg),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: PersonnelSpacing.sm),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedId == item.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(PersonnelRadius.sm),
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? PersonnelColors.brandAccent
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? PersonnelColors.brandAccent
                                : Colors.white70,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? PersonnelColors.brandAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(PersonnelRadius.sm),
                          ),
                          onTap: () => onSelected(item.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(PersonnelSpacing.md),
              child: Text(
                'Portail métier v1',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _locationLine(String? stationName, String? counterName) {
    final parts = <String>[
      if (stationName != null && stationName.isNotEmpty) stationName,
      if (counterName != null && counterName.isNotEmpty) counterName,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }
}
