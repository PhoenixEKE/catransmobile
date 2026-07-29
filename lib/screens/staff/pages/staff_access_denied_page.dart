import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/services/auth_service.dart';

/// Shown by `StaffShellScreen` (and, pre-existing, by several admin module
/// screens when the current scope check fails) when the session cannot use
/// the staff portal. Fixed per LOT 6.8A P0 finding: this used to be a dead
/// end with no way out; it now always offers a working recovery action.
///
/// [user] is optional and read from the constructor rather than from
/// `Provider`/`AuthService` directly: several existing call sites (the
/// admin dashboard/users/transport/operations home screens, none of which
/// this lot is allowed to touch) construct this page with no arguments and
/// with no `AuthService` provider in their widget tree in tests. Reading
/// from `Provider` in `build()` would have thrown in those contexts; the
/// action buttons only touch `AuthService` lazily, on tap.
class StaffAccessDeniedPage extends StatelessWidget {
  final User? user;

  const StaffAccessDeniedPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final isCustomer = user?.isCustomer ?? false;

    return Scaffold(
      backgroundColor: PersonnelColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PersonnelSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(PersonnelSpacing.xl),
                decoration: BoxDecoration(
                  color: PersonnelColors.surface,
                  borderRadius: BorderRadius.circular(PersonnelRadius.lg),
                  border: Border.all(color: PersonnelColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: PersonnelColors.brandPrimary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(PersonnelRadius.md),
                      ),
                      child: const Icon(
                        Icons.no_accounts_outlined,
                        color: PersonnelColors.brandPrimary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: PersonnelSpacing.lg),
                    const Text(
                      'Accès personnel indisponible',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PersonnelColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: PersonnelSpacing.sm),
                    Text(
                      isCustomer
                          ? 'Ce compte est un compte voyageur. Le portail '
                              'personnel CA TRANS est réservé aux équipes '
                              'internes.'
                          : 'Votre session ne permet pas d\'accéder au '
                              'portail personnel. Reconnectez-vous ou '
                              'contactez un administrateur CA TRANS.',
                      style: const TextStyle(
                        color: PersonnelColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: PersonnelSpacing.xl),
                    if (isCustomer) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _returnToTravellerApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PersonnelColors.brandPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(PersonnelRadius.md),
                            ),
                          ),
                          icon: const Icon(Icons.directions_bus),
                          label: const Text('Retour à l\'application voyageur'),
                        ),
                      ),
                      const SizedBox(height: PersonnelSpacing.sm),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PersonnelColors.danger,
                          side: const BorderSide(color: PersonnelColors.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(PersonnelRadius.md),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _returnToTravellerApp(BuildContext context) {
    context.go(RoutePaths.accueil);
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    context.go(RoutePaths.root);
  }
}
