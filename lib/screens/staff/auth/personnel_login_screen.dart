import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/design/personnel_design.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/services/auth_service.dart';

/// Email + password login form for CA TRANS staff.
///
/// This is the sole internal authentication entry point: it reuses the
/// existing `POST /api/v1/auth/internal/token/` contract via
/// `AuthService.loginInternal` and never touches the customer
/// phone/password contract. It performs the network call only and reports
/// the resulting [User] to [onLoginSuccess]; it does not decide navigation
/// itself so the caller (`PersonnelEntryScreen`) stays the single place that
/// decides what to do with the authenticated user (redirect by role, or
/// reject a customer account).
class PersonnelLoginScreen extends StatefulWidget {
  final ValueChanged<User> onLoginSuccess;

  const PersonnelLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<PersonnelLoginScreen> createState() => _PersonnelLoginScreenState();
}

class _PersonnelLoginScreenState extends State<PersonnelLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final authService = context.read<AuthService>();
    final success = await authService.loginInternal(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (!success || authService.currentUser == null) {
      setState(() {
        _isSubmitting = false;
        _inlineError =
            authService.errorMessage ?? 'Email ou mot de passe incorrect.';
      });
      return;
    }

    setState(() => _isSubmitting = false);
    widget.onLoginSuccess(authService.currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PersonnelColors.brandPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PersonnelSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(PersonnelSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      height: 72,
                      width: 72,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.directions_bus,
                          size: 56,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: PersonnelSpacing.lg),
                  const Text(
                    'Espace personnel CA TRANS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PersonnelColors.brandAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: PersonnelSpacing.sm),
                  const Text(
                    'Connexion réservée aux équipes CA TRANS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: PersonnelSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(PersonnelSpacing.lg),
                    decoration: BoxDecoration(
                      color: PersonnelColors.surface,
                      borderRadius: BorderRadius.circular(PersonnelRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Email professionnel',
                              prefixIcon: Icon(
                                Icons.email,
                                color: PersonnelColors.brandPrimary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(PersonnelRadius.md),
                                ),
                              ),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!email.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: PersonnelSpacing.md),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) =>
                                _isSubmitting ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: PersonnelColors.brandPrimary,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher le mot de passe'
                                    : 'Masquer le mot de passe',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(PersonnelRadius.md),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer votre mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Mot de passe trop court';
                              }
                              return null;
                            },
                          ),
                          if (_inlineError != null) ...[
                            const SizedBox(height: PersonnelSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(
                                PersonnelSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: PersonnelColors.dangerSurface,
                                borderRadius: BorderRadius.circular(
                                  PersonnelRadius.sm,
                                ),
                                border: Border.all(
                                  color: PersonnelColors.danger
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _inlineError!,
                                style: const TextStyle(
                                  color: PersonnelColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: PersonnelSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PersonnelColors.brandAccent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    PersonnelRadius.md,
                                  ),
                                ),
                                elevation: 3,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'SE CONNECTER',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: PersonnelSpacing.sm),
                          const Text(
                            'Utilisez votre compte personnel CA TRANS.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: PersonnelColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
