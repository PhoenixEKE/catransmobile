import 'package:catrans_app/core/network/api_exception.dart';

class WaveCheckoutSessionRequest {
  final String reservationId;

  const WaveCheckoutSessionRequest({
    required this.reservationId,
  });

  Map<String, dynamic> toJson() {
    final normalizedReservationId = reservationId.trim();
    if (normalizedReservationId.isEmpty) {
      throw ApiException(
        message: 'La reservation a payer est introuvable.',
      );
    }

    return {
      'reservation_id': normalizedReservationId,
    };
  }
}
