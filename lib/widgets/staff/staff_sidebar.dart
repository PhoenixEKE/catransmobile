import 'package:flutter/material.dart';

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

    return Container(
      width: 280,
      color: const Color(0xFF0F056B),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedId == item.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? const Color(0xFFEFD807)
                            : Colors.white70,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFEFD807)
                              : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () => onSelected(item.id),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
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
}
