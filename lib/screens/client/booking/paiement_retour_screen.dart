import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';
import 'package:catrans_app/screens/client/booking/paiement_screen.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/services/pending_reservation_resume.dart';
import 'package:catrans_app/services/pending_wave_reservation_storage.dart';

enum _RetourStatus { checking, success, unresolved }

/// Landing screen for Wave's `success_url`/`error_url` redirect.
///
/// Wave recommends never trusting the redirect URL alone as proof of
/// payment (it can be incomplete or replayed) — this screen always
/// re-verifies the real status through the existing authenticated
/// `wave/reservations/{id}/current/` endpoint before showing anything.
///
/// `isSuccessRedirect` only seeds the tone shown while checking; it never
/// decides the outcome by itself.
class PaiementRetourScreen extends StatefulWidget {
  final bool isSuccessRedirect;

  const PaiementRetourScreen({super.key, required this.isSuccessRedirect});

  @override
  State<PaiementRetourScreen> createState() => _PaiementRetourScreenState();
}

class _PaiementRetourScreenState extends State<PaiementRetourScreen> {
  _RetourStatus _status = _RetourStatus.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final reservationId = await readPendingWaveReservationId();

    ReservationDetail? reservation;
    if (reservationId != null) {
      try {
        reservation = await ReservationApiService()
            .getReservationDetail(reservationId: reservationId);
      } catch (_) {
        reservation = null;
      }
    }

    reservation ??= await loadPendingReservation();

    if (!mounted) return;

    if (reservation == null) {
      await clearPendingWaveReservationId();
      if (!mounted) return;
      setState(() => _status = _RetourStatus.unresolved);
      return;
    }

    final currentPayment = await loadCurrentWavePayment(reservation);
    if (!mounted) return;

    if (currentPayment?.isPaymentSuccess == true) {
      await clearPendingWaveReservationId();
      if (!mounted) return;
      setState(() => _status = _RetourStatus.success);
      return;
    }

    if (currentPayment?.shouldGoToPaymentScreen == true) {
      final resumeScreen = buildPendingReservationResumeScreen(
        reservation,
        currentPayment,
      );
      if (resumeScreen is PaiementScreen) {
        context.go(RoutePaths.paiement, extra: resumeScreen);
        return;
      }
    }

    await clearPendingWaveReservationId();
    if (!mounted) return;
    setState(() => _status = _RetourStatus.unresolved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_status) {
              _RetourStatus.checking => _buildChecking(),
              _RetourStatus.success => _buildSuccess(),
              _RetourStatus.unresolved => _buildUnresolved(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChecking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Color(0xFF0F056B)),
        const SizedBox(height: 20),
        const Text(
          'Vérification du paiement...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Merci de patienter, nous confirmons le statut réel auprès de Wave.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 20),
        const Text(
          'Paiement confirmé',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre réservation est validée. Votre billet est disponible dans "Mes réservations".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => context.go(RoutePaths.mesReservations),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFD807),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'VOIR MES BILLETS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnresolved() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.isSuccessRedirect ? Icons.info_outline : Icons.error_outline,
          color: widget.isSuccessRedirect ? Colors.orange : Colors.red,
          size: 72,
        ),
        const SizedBox(height: 20),
        Text(
          widget.isSuccessRedirect
              ? 'Statut du paiement introuvable'
              : 'Le paiement n’a pas abouti',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Aucune réservation en attente n’a été retrouvée depuis cet appareil. '
          'Consultez vos réservations pour voir l’état réel de votre paiement.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => context.go(RoutePaths.mesReservations),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFD807),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'MES RÉSERVATIONS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: () => context.go(RoutePaths.accueil),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F056B),
              side: const BorderSide(color: Color(0xFF0F056B), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'RETOUR À L’ACCUEIL',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
