import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/services/auth_service.dart';

class StaffProfileIncompletePage extends StatelessWidget {
  const StaffProfileIncompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: PersonnelColors.background,
      appBar: AppBar(
        title: const Text('Profil interne incomplet'),
        backgroundColor: PersonnelColors.brandPrimary,
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
            margin: const EdgeInsets.all(PersonnelSpacing.lg),
            padding: const EdgeInsets.all(PersonnelSpacing.lg),
            decoration: BoxDecoration(
              color: PersonnelColors.surface,
              borderRadius: BorderRadius.circular(PersonnelRadius.sm),
              border: Border.all(color: PersonnelColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.manage_accounts,
                  color: PersonnelColors.brandPrimary,
                  size: 44,
                ),
                const SizedBox(height: PersonnelSpacing.md),
                const Text(
                  'Votre profil interne doit être complété',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: PersonnelColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: PersonnelSpacing.sm),
                Text(
                  user?.email ?? 'Compte personnel CA TRANS',
                  style: const TextStyle(color: PersonnelColors.textMuted),
                ),
                const SizedBox(height: PersonnelSpacing.md),
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
