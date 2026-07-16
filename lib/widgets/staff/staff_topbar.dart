import 'package:flutter/material.dart';

import 'package:catrans_app/models/accounts/user.dart';

class StaffTopbar extends StatelessWidget {
  final User user;
  final String title;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE6E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onOpenMenu != null) ...[
            IconButton(
              tooltip: 'Menu',
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: 8),
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
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _identityLine(station?.name, counter?.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
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
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: const Color(0xFF0F056B),
            child: Text(
              _initials(user),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
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
