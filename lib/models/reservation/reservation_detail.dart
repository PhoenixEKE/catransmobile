import 'package:catrans_app/models/reservation/reservation_item_detail.dart';

class ReservationDetail {
  final String id;
  final String reference;
  final String status;
  final String totalAmount;
  final String currency;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final List<ReservationItemDetail> items;

  const ReservationDetail({
    required this.id,
    required this.reference,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    this.createdAt,
    required this.items,
  });

  bool get isPendingPayment => status == 'pending_payment';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';
  bool get isPayable => isPendingPayment && !isExpired;
  bool get hasSeatAssigned => items.any((item) => item.hasSeat);
  bool get isEconomyWithoutSeat => items.isNotEmpty && !hasSeatAssigned;
  DateTime? get localExpiresAt => expiresAt?.toLocal();

  factory ReservationDetail.fromJson(Map<String, dynamic> json) {
    return ReservationDetail(
      id: _readString(json['id']) ?? '',
      reference: _readString(json['reference']) ?? '',
      status: _readString(json['status']) ?? '',
      totalAmount: _readAmount(json['total_amount']),
      currency: _readString(json['currency']) ?? 'XOF',
      expiresAt: _readDate(json['expires_at']),
      confirmedAt: _readDate(json['confirmed_at']),
      cancelledAt: _readDate(json['cancelled_at']),
      createdAt: _readDate(json['created_at']),
      items: _readItems(json['items']),
    );
  }

  static List<ReservationItemDetail> _readItems(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => ReservationItemDetail.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
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

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
