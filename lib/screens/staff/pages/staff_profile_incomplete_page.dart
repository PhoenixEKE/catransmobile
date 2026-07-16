import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/services/auth_service.dart';

class StaffProfileIncompletePage extends StatelessWidget {
  const StaffProfileIncompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Profil interne incomplet'),
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
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.manage_accounts,
                  color: Color(0xFF0F056B),
                  size: 44,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre profil interne doit être complété',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F056B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Compte personnel CA TRANS',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Votre compte est reconnu, mais aucun rôle métier exploitable n’est encore configuré. Contactez un administrateur CA TRANS.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
