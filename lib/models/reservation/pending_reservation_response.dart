import 'package:catrans_app/models/reservation/reservation_detail.dart';

class PendingReservationResponse {
  final ReservationDetail? reservation;
  final int remainingSeconds;

  const PendingReservationResponse({
    this.reservation,
    required this.remainingSeconds,
  });

  bool get hasActiveReservation => reservation != null && remainingSeconds > 0;
  Duration get remainingDuration => Duration(seconds: remainingSeconds);
  DateTime? get expiresAt => reservation?.expiresAt;

  factory PendingReservationResponse.fromJson(Map<String, dynamic> json) {
    final reservationData = json['reservation'];
    return PendingReservationResponse(
      reservation: reservationData is Map
          ? ReservationDetail.fromJson(
              Map<String, dynamic>.from(reservationData))
          : null,
      remainingSeconds: _readInt(json['remaining_seconds']) ?? 0,
    );
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
