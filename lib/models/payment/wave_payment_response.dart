import 'package:catrans_app/models/payment/wave_payment_info.dart';

class WavePaymentResponse {
  final String paymentId;
  final String paymentReference;
  final String reservationId;
  final String reservationReference;
  final String amount;
  final String currency;
  final String status;
  final String provider;
  final DateTime? reservationExpiresAt;
  final int remainingSeconds;
  final WavePaymentInfo? wave;
  final String? message;

  const WavePaymentResponse({
    required this.paymentId,
    required this.paymentReference,
    required this.reservationId,
    required this.reservationReference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    this.reservationExpiresAt,
    required this.remainingSeconds,
    this.wave,
    this.message,
  });

  bool get isInitiated => status == 'initiated';
  bool get isProcessing => status == 'processing';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isAnomaly => status == 'anomaly';
  bool get isPendingLike =>
      status == 'pending' || status == 'initiated' || status == 'processing';
  bool get isTerminal =>
      isSuccess ||
      isFailed ||
      isCancelled ||
      isExpired ||
      status == 'refunded' ||
      isAnomaly;
  bool get canOpenWave => isPendingLike && (wave?.hasLaunchUrl ?? false);
  bool get canCheckStatus => paymentId.trim().isNotEmpty;
  bool get isReservationStillPending =>
      isPendingLike && remainingSeconds > 0 && reservationExpiresAt != null;
  DateTime? get localReservationExpiresAt => reservationExpiresAt?.toLocal();
  Duration get remainingDuration => Duration(seconds: remainingSeconds);

  factory WavePaymentResponse.fromJson(Map<String, dynamic> json) {
    return WavePaymentResponse(
      paymentId: _readString(json['payment_id']) ?? '',
      paymentReference: _readString(json['payment_reference']) ?? '',
      reservationId: _readString(json['reservation_id']) ?? '',
      reservationReference: _readString(json['reservation_reference']) ?? '',
      amount: _readAmount(json['amount']),
      currency: _readString(json['currency']) ?? 'XOF',
      status: _readString(json['status']) ?? '',
      provider: _readString(json['provider']) ?? '',
      reservationExpiresAt: _readDate(json['reservation_expires_at']),
      remainingSeconds: _readInt(json['remaining_seconds']) ?? 0,
      wave: _readWave(json['wave']),
      message: _readString(json['message']),
    );
  }

  static WavePaymentInfo? _readWave(dynamic value) {
    if (value is Map<String, dynamic>) {
      return WavePaymentInfo.fromJson(value);
    }
    if (value is Map) {
      return WavePaymentInfo.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static String _readAmount(dynamic value) {
    if (value == null) return '0.00';
    if (value is num) return value.toStringAsFixed(2);
    return value.toString();
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
