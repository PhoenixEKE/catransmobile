import 'package:flutter/widgets.dart';

import 'package:catrans_app/models/payment/wave_current_payment_response.dart';
import 'package:catrans_app/models/reservation/reservation_detail.dart';
import 'package:catrans_app/services/api/payment_api_service.dart';
import 'package:catrans_app/services/api/reservation_api_service.dart';
import 'package:catrans_app/screens/client/booking/paiement_screen.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';

/// Looks up the reservation still pending payment for the current user, if
/// any, and builds the screen that should be shown to resume it.
///
/// Shared between [SplashScreen] (cold app start) and the Wave
/// success/error return screens, so both rely on the exact same proven
/// mechanism instead of duplicating it.
Future<ReservationDetail?> loadPendingReservation() async {
  try {
    final pending = await ReservationApiService().getCurrentPendingReservation();
    return pending.hasActiveReservation ? pending.reservation : null;
  } catch (_) {
    return null;
  }
}

Future<WaveCurrentPaymentResponse?> loadCurrentWavePayment(
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

Widget buildPendingReservationResumeScreen(
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
