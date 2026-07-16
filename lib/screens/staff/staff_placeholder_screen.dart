import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/services/auth_service.dart';

class StaffPlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const StaffPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  factory StaffPlaceholderScreen.forUser(User user) {
    final role = user.internalProfile?.role;
    switch (role) {
      case InternalRole.station_manager:
        return const StaffPlaceholderScreen(
          title: 'Portail chef de gare',
          subtitle:
              'Les opérations de gare seront branchées dans un prochain lot.',
        );
      case InternalRole.cashier:
        return const StaffPlaceholderScreen(
          title: 'Portail guichet',
          subtitle: 'La vente guichet sera branchée dans un prochain lot.',
        );
      case InternalRole.station_agent:
        return const StaffPlaceholderScreen(
          title: 'Portail embarquement',
          subtitle:
              'La validation embarquement sera branchée dans un prochain lot.',
        );
      case InternalRole.support:
        return const StaffPlaceholderScreen(
          title: 'Portail support',
          subtitle: 'Les outils support seront branchés dans un prochain lot.',
        );
      case InternalRole.accounting:
        return const StaffPlaceholderScreen(
          title: 'Portail comptabilité',
          subtitle:
              'Les rapports financiers seront branchés dans un prochain lot.',
        );
      case InternalRole.marketing:
        return const StaffPlaceholderScreen(
          title: 'Accès marketing',
          subtitle:
              'Ce rôle est reconnu mais son portail n’est pas encore disponible.',
        );
      case InternalRole.legacy_unknown:
        return const StaffPlaceholderScreen(
          title: 'Profil interne incomplet',
          subtitle:
              'Votre profil doit être complété avant l’accès aux outils CA TRANS.',
        );
      case InternalRole.admin:
      case InternalRole.director:
      case null:
        return const StaffPlaceholderScreen(
          title: 'Accès personnel CA TRANS',
          subtitle:
              'Votre profil est reconnu, mais aucun portail dédié n’est encore disponible.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final profile = user?.internalProfile;
    final station = profile?.station;
    final counter = profile?.counter;
    final scopes = user?.scopes ?? const <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                _InfoPanel(
                  children: [
                    _InfoRow(label: 'Nom', value: user?.fullName ?? '-'),
                    _InfoRow(label: 'Email', value: user?.email ?? '-'),
                    _InfoRow(
                        label: 'Rôle',
                        value: profile?.roleLabel ?? profile?.role.name ?? '-'),
                    if (station != null)
                      _InfoRow(label: 'Gare', value: station.name),
                    if (counter != null)
                      _InfoRow(label: 'Guichet', value: counter.displayName),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoPanel(
                  title: 'Scopes principaux',
                  children: scopes.isEmpty
                      ? const [
                          _InfoRow(
                              label: 'Accès', value: 'Aucun scope disponible')
                        ]
                      : scopes.take(8).map((scope) {
                          return _InfoRow(label: 'Scope', value: scope);
                        }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await context.read<AuthService>().logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _InfoPanel({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F056B),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
