import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/staff/auth/personnel_login_screen.dart';
import 'package:catrans_app/services/auth_redirect_service.dart';
import 'package:catrans_app/services/auth_service.dart';

enum _PersonnelEntryPhase { resolving, loginForm, customerBlocked }

/// Entry point mounted at the `/personnel` route.
///
/// Branches on the current auth state (see LOT 6.8B1 report §2):
/// - no user: shows [PersonnelLoginScreen] (email + password only);
/// - staff user (any role, complete or incomplete profile): redirected via
///   `AuthRedirectService.pathForUser`, which already handles the
///   incomplete-profile case;
/// - customer user: shown a dedicated "reserved for staff" state instead of
///   silently opening (or silently leaving) the staff portal.
class PersonnelEntryScreen extends StatefulWidget {
  const PersonnelEntryScreen({super.key});

  @override
  State<PersonnelEntryScreen> createState() => _PersonnelEntryScreenState();
}

class _PersonnelEntryScreenState extends State<PersonnelEntryScreen> {
  _PersonnelEntryPhase _phase = _PersonnelEntryPhase.resolving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final authService = context.read<AuthService>();
    await authService.loadUser();
    if (!mounted) return;

    final user = authService.currentUser;
    if (user == null) {
      setState(() => _phase = _PersonnelEntryPhase.loginForm);
      return;
    }

    _handleAuthenticatedUser(user);
  }

  void _handleAuthenticatedUser(User user) {
    if (user.isCustomer) {
      setState(() => _phase = _PersonnelEntryPhase.customerBlocked);
      return;
    }

    context.go(AuthRedirectService.pathForUser(user));
  }

  Future<void> _handleLoginSuccess(User user) async {
    if (user.isCustomer) {
      // The internal login contract should never authenticate a customer
      // account, but refuse cleanly rather than silently opening (or
      // silently bouncing out of) the staff portal if it ever does.
      await context.read<AuthService>().logout();
      if (!mounted) return;
      setState(() => _phase = _PersonnelEntryPhase.loginForm);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ce compte est un compte voyageur. Utilisez l\'application '
            'voyageur pour vous connecter.',
          ),
          backgroundColor: PersonnelColors.danger,
        ),
      );
      return;
    }

    _handleAuthenticatedUser(user);
  }

  Future<void> _returnToTravellerApp() async {
    context.go(RoutePaths.accueil);
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    setState(() => _phase = _PersonnelEntryPhase.loginForm);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _PersonnelEntryPhase.resolving:
        return const _PersonnelEntryLoadingView();
      case _PersonnelEntryPhase.loginForm:
        return PersonnelLoginScreen(onLoginSuccess: _handleLoginSuccess);
      case _PersonnelEntryPhase.customerBlocked:
        return _PersonnelCustomerBlockedView(
          onReturnToTravellerApp: _returnToTravellerApp,
          onLogout: _logout,
        );
    }
  }
}

class _PersonnelEntryLoadingView extends StatelessWidget {
  const _PersonnelEntryLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PersonnelColors.brandPrimary,
      body: Center(
        child: CircularProgressIndicator(color: PersonnelColors.brandAccent),
      ),
    );
  }
}

class _PersonnelCustomerBlockedView extends StatelessWidget {
  final VoidCallback onReturnToTravellerApp;
  final VoidCallback onLogout;

  const _PersonnelCustomerBlockedView({
    required this.onReturnToTravellerApp,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
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
                        Icons.lock_outline,
                        color: PersonnelColors.brandPrimary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: PersonnelSpacing.lg),
                    const Text(
                      'Espace réservé au personnel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PersonnelColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: PersonnelSpacing.sm),
                    const Text(
                      'Ce compte est un compte voyageur. Le portail '
                      'personnel CA TRANS est réservé aux équipes internes.',
                      style: TextStyle(color: PersonnelColors.textSecondary),
                    ),
                    const SizedBox(height: PersonnelSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onReturnToTravellerApp,
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onLogout,
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
}
