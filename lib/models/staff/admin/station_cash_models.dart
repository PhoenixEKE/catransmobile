import 'package:catrans_app/models/staff/paged_result.dart';

class StationCashSaleItemRequest {
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final bool isForCustomer;
  final bool useLoyaltyPoints;

  const StationCashSaleItemRequest({
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    this.isForCustomer = false,
    this.useLoyaltyPoints = false,
  });

  Map<String, dynamic> toJson() => {
        'is_for_customer': isForCustomer,
        'use_loyalty_points': useLoyaltyPoints,
        if (travelerLastname != null) 'traveler_lastname': travelerLastname,
        if (travelerFirstname != null) 'traveler_firstname': travelerFirstname,
        if (travelerPhone != null) 'traveler_phone': travelerPhone,
      };
}

class StationCashSaleCreateRequest {
  final String departureId;
  final String serviceClassCode;
  final List<StationCashSaleItemRequest> items;
  final String? note;

  const StationCashSaleCreateRequest({
    required this.departureId,
    required this.serviceClassCode,
    required this.items,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'departure_id': departureId,
        'service_class_code': serviceClassCode,
        'items': items.map((item) => item.toJson()).toList(),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

class StationCashSaleCreateResponse {
  final String reservationId;
  final String reference;
  final String status;
  final String totalAmount;
  final String currency;
  final Map<String, dynamic> raw;

  const StationCashSaleCreateResponse({
    required this.reservationId,
    required this.reference,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.raw = const {},
  });

  factory StationCashSaleCreateResponse.fromJson(JsonMap json) {
    final reservation = json['reservation'] is Map
        ? Map<String, dynamic>.from(json['reservation'] as Map)
        : json;
    return StationCashSaleCreateResponse(
      reservationId:
          (reservation['id'] ?? json['reservation_id'] ?? '').toString(),
      reference:
          (reservation['reference'] ?? json['reference'] ?? '').toString(),
      status: (reservation['status'] ?? json['status'] ?? '').toString(),
      totalAmount: (reservation['total_amount'] ?? json['total_amount'] ?? '')
          .toString(),
      currency:
          (reservation['currency'] ?? json['currency'] ?? 'XOF').toString(),
      raw: json,
    );
  }
}

class StationCashConfirmResponse {
  final String reservationId;
  final String paymentId;
  final String status;
  final String detail;
  final Map<String, dynamic> raw;

  const StationCashConfirmResponse({
    required this.reservationId,
    required this.paymentId,
    required this.status,
    required this.detail,
    this.raw = const {},
  });

  factory StationCashConfirmResponse.fromJson(JsonMap json) {
    final reservation = json['reservation'] is Map
        ? Map<String, dynamic>.from(json['reservation'] as Map)
        : const <String, dynamic>{};
    final payment = json['payment'] is Map
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : const <String, dynamic>{};
    return StationCashConfirmResponse(
      reservationId:
          (json['reservation_id'] ?? reservation['id'] ?? '').toString(),
      paymentId: (json['payment_id'] ?? payment['id'] ?? '').toString(),
      status:
          (json['status'] ?? reservation['status'] ?? payment['status'] ?? '')
              .toString(),
      detail: (json['detail'] ?? json['message'] ?? '').toString(),
      raw: json,
    );
  }
}
