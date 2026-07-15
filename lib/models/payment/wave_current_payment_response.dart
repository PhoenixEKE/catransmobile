import 'package:catrans_app/models/payment/wave_payment_response.dart';

class WaveCurrentPaymentResponse {
  final bool hasPayment;
  final WavePaymentResponse? payment;
  final String reservationId;
  final String? reservationReference;
  final String? reservationStatus;
  final String? reservationStatusLabel;
  final bool canStartNewPayment;

  const WaveCurrentPaymentResponse({
    required this.hasPayment,
    this.payment,
    required this.reservationId,
    this.reservationReference,
    this.reservationStatus,
    this.reservationStatusLabel,
    required this.canStartNewPayment,
  });

  bool get hasActivePayment => hasPayment && (payment?.isPendingLike ?? false);
  bool get isPaymentSuccess => payment?.isSuccess == true;
  bool get canResumePayment =>
      hasActivePayment && (payment?.wave?.hasLaunchUrl ?? false);
  bool get shouldGoToPaymentScreen => hasPayment;

  factory WaveCurrentPaymentResponse.fromJson(Map<String, dynamic> json) {
    final paymentData = json['payment'];
    return WaveCurrentPaymentResponse(
      hasPayment: _readBool(json['has_payment']),
      payment: paymentData is Map
          ? WavePaymentResponse.fromJson(Map<String, dynamic>.from(paymentData))
          : null,
      reservationId: _readString(json['reservation_id']) ?? '',
      reservationReference: _readString(json['reservation_reference']),
      reservationStatus: _readString(json['reservation_status']),
      reservationStatusLabel: _readString(json['reservation_status_label']),
      canStartNewPayment: _readBool(json['can_start_new_payment']),
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
