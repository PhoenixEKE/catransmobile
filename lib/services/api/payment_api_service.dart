import 'package:catrans_app/core/network/api_client.dart';
import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/payment/wave_checkout_session_request.dart';
import 'package:catrans_app/models/payment/wave_current_payment_response.dart';
import 'package:catrans_app/models/payment/wave_payment_response.dart';

class PaymentApiService {
  final ApiClient _apiClient;

  PaymentApiService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  Future<WavePaymentResponse> createWaveCheckoutSession({
    required String reservationId,
  }) async {
    if (reservationId.trim().isEmpty) {
      throw ApiException(
        message: 'La reservation a payer est introuvable.',
      );
    }

    final request = WaveCheckoutSessionRequest(reservationId: reservationId);
    final response = await _apiClient.post(
      'payments/wave/checkout-sessions/',
      data: request.toJson(),
    );

    return WavePaymentResponse.fromJson(_readObject(response.data));
  }

  Future<WavePaymentResponse> getWavePaymentStatus({
    required String paymentId,
  }) async {
    final normalizedPaymentId = paymentId.trim();
    if (normalizedPaymentId.isEmpty) {
      throw ApiException(
        message: 'Le paiement Wave est introuvable.',
      );
    }

    final response = await _apiClient.get(
      'payments/wave/sessions/$normalizedPaymentId/status/',
    );

    return WavePaymentResponse.fromJson(_readObject(response.data));
  }

  Future<WaveCurrentPaymentResponse> getCurrentWavePaymentForReservation({
    required String reservationId,
  }) async {
    final normalizedReservationId = reservationId.trim();
    if (normalizedReservationId.isEmpty) {
      throw ApiException(
        message: 'La reservation est introuvable.',
      );
    }

    final response = await _apiClient.get(
      'payments/wave/reservations/$normalizedReservationId/current/',
    );

    return WaveCurrentPaymentResponse.fromJson(_readObject(response.data));
  }

  Map<String, dynamic> _readObject(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    throw ApiException(
      message: 'Reponse paiement Wave invalide.',
      details: data,
    );
  }
}
