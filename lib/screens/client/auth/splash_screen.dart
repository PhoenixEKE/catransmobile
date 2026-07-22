import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/services/auth_redirect_service.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/models/payment/wave_current_payment_response.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';
import 'package:catrans_app/services/api/payment_api_service.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/screens/client/booking/paiement_screen.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navigateToAuth();
      }
    });
  }

  Future<void> _navigateToAuth() async {
    final authService = context.read<AuthService>();
    // Set by the go_router redirect guard when a direct link to a
    // protected path was loaded before auth state was known (see
    // app_router.dart's `resumableAfterSplashPaths`); lets the user land
    // where they actually asked to go instead of always on the default
    // destination for their role.
    final from = GoRouterState.of(context).uri.queryParameters['from'];

    await Future.wait([
      Future.delayed(const Duration(seconds: 5)),
      authService.loadUser(),
    ]);

    if (!mounted) return;

    void goToRoleDefaultOrFrom(String roleDefault) {
      if (from != null && resumableAfterSplashPaths.contains(from)) {
        context.go(from);
      } else {
        context.go(roleDefault);
      }
    }

    final currentUser = authService.currentUser;
    if (authService.isAuthenticated && currentUser != null) {
      if (!currentUser.isCustomer) {
        goToRoleDefaultOrFrom(AuthRedirectService.pathForUser(currentUser));
        return;
      }

      final pendingReservation = await _loadPendingReservation();
      if (!mounted) return;

      if (pendingReservation != null) {
        final currentPayment =
            await _loadCurrentWavePayment(pendingReservation);
        if (!mounted) return;

        final resumeScreen = _resumePendingReservationScreen(
          pendingReservation,
          currentPayment,
        );
        if (resumeScreen is PaiementScreen) {
          context.go(RoutePaths.paiement, extra: resumeScreen);
        } else {
          context.go(RoutePaths.recapitulatif, extra: resumeScreen);
        }
        return;
      }

      goToRoleDefaultOrFrom(AuthRedirectService.pathForUser(currentUser));
      return;
    }

    goToRoleDefaultOrFrom(RoutePaths.bienvenue);
  }

  Future<ReservationDetail?> _loadPendingReservation() async {
    try {
      final pending =
          await ReservationApiService().getCurrentPendingReservation();
      return pending.hasActiveReservation ? pending.reservation : null;
    } catch (_) {
      return null;
    }
  }

  Future<WaveCurrentPaymentResponse?> _loadCurrentWavePayment(
    ReservationDetail reservation,
  ) async {
    try {
      return await PaymentApiService().getCurrentWavePaymentForReservation(
        reservationId: reservation.id,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _resumePendingReservationScreen(
    ReservationDetail reservation,
    WaveCurrentPaymentResponse? currentPayment,
  ) {
    final payment = currentPayment?.payment;
    if (currentPayment?.shouldGoToPaymentScreen == true && payment != null) {
      final recap = RecapitulatifScreen.fromReservation(
        reservationDetail: reservation,
        isBlockingPendingResume: true,
      );

      return PaiementScreen(
        reservationDetail: reservation,
        depart: recap.depart,
        arrivee: recap.arrivee,
        date: recap.date,
        heure: recap.heure,
        prix: recap.prix,
        nombrePassagers: recap.nombrePassagers,
        points: recap.points,
        classe: recap.classe,
        passagers: recap.passagers,
        total: double.tryParse(reservation.totalAmount) ?? recap.prix,
        existingPayment: payment,
        canStartNewPayment: currentPayment?.canStartNewPayment ?? false,
      );
    }

    return RecapitulatifScreen.fromReservation(
      reservationDetail: reservation,
      isBlockingPendingResume: true,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F056B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.directions_bus,
                        size: 150, color: Colors.white);
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Voyagez sans stress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Réservez, payez et voyagez en toute tranquillité',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F056B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Image.asset(
                'assets/icons/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.directions_bus,
                      size: 120, color: Colors.white);
                },
              ),
              const SizedBox(height: 30),

              // Texte
              const Text(
                'Voyagez sans stress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Réservez, payez et voyagez en toute tranquillité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 3),

              // Bouton SE CONNECTER
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(RoutePaths.connexion);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFD807),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'SE CONNECTER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Bouton CRÉER UN COMPTE
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(RoutePaths.inscription);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CRÉER UN COMPTE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
