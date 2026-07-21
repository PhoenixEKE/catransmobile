import 'package:catrans_app/models/station/station_reservation_detail.dart';

typedef JsonMap = Map<String, dynamic>;

class StationCashSaleItemRequest {
  final bool isForCustomer;
  final int? seatNumber;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final String? note;

  const StationCashSaleItemRequest({
    this.isForCustomer = true,
    this.seatNumber,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'is_for_customer': isForCustomer,
        if (seatNumber != null) 'seat_number': seatNumber,
        if (travelerLastname != null) 'traveler_lastname': travelerLastname,
        if (travelerFirstname != null) 'traveler_firstname': travelerFirstname,
        if (travelerPhone != null) 'traveler_phone': travelerPhone,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

class StationCashSaleCreateRequest {
  final String departureId;
  final String serviceClassCode;
  final String customerId;
  final List<StationCashSaleItemRequest> items;
  final String? note;

  const StationCashSaleCreateRequest({
    required this.departureId,
    required this.serviceClassCode,
    this.customerId = '',
    required this.items,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'departure_id': departureId.trim(),
        'service_class_code': serviceClassCode.trim().toUpperCase(),
        'customer_id': customerId.trim(),
        'items': items.map((item) => item.toJson()).toList(),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

class StationCashSaleCreateResponse {
  final StationReservationDetail reservation;
  final DateTime? expiresAt;
  final String totalAmount;
  final String currency;
  final int itemCount;
  final bool canConfirmCash;
  final JsonMap raw;

  const StationCashSaleCreateResponse({
    required this.reservation,
    this.expiresAt,
    required this.totalAmount,
    required this.currency,
    required this.itemCount,
    required this.canConfirmCash,
    this.raw = const {},
  });

  factory StationCashSaleCreateResponse.fromJson(JsonMap json) {
    final reservationMap = _readMap(json['reservation']);
    return StationCashSaleCreateResponse(
      reservation: StationReservationDetail.fromJson(reservationMap),
      expiresAt: _readDateTime(json['expires_at']),
      totalAmount: _readString(json['total_amount']),
      currency: _readString(json['currency']),
      itemCount: _readInt(json['item_count']),
      canConfirmCash: json['can_confirm_cash'] == true,
      raw: json,
    );
  }

  String get reservationId => reservation.id;
}

class StationCashConfirmResponse {
  final bool alreadyPaid;
  final StationReservationDetail reservation;
  final StationCashPaymentSummary payment;
  final List<StationCashTicketSummary> tickets;
  final JsonMap raw;

  const StationCashConfirmResponse({
    required this.alreadyPaid,
    required this.reservation,
    required this.payment,
    required this.tickets,
    this.raw = const {},
  });

  factory StationCashConfirmResponse.fromJson(JsonMap json) {
    return StationCashConfirmResponse(
      alreadyPaid: json['already_paid'] == true,
      reservation:
          StationReservationDetail.fromJson(_readMap(json['reservation'])),
      payment: StationCashPaymentSummary.fromJson(_readMap(json['payment'])),
      tickets: _readList(json['tickets'])
          .map((item) => StationCashTicketSummary.fromJson(_readMap(item)))
          .toList(),
      raw: json,
    );
  }

  String get paymentId => payment.id;
}

class StationCashPaymentSummary {
  final String id;
  final String reference;
  final String status;
  final String method;
  final String provider;
  final String amount;
  final String currency;
  final DateTime? paidAt;

  const StationCashPaymentSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.method,
    required this.provider,
    required this.amount,
    required this.currency,
    this.paidAt,
  });

  String get displayAmount => '$amount $currency'.trim();

  factory StationCashPaymentSummary.fromJson(JsonMap json) {
    return StationCashPaymentSummary(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      method: _readString(json['method']),
      provider: _readString(json['provider']),
      amount: _readString(json['amount']),
      currency: _readString(json['currency']),
      paidAt: _readDateTime(json['paid_at']),
    );
  }
}

class StationCashTicketSummary {
  final String id;
  final String reference;
  final String status;
  final int? seatNumber;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final String amount;
  final String currency;
  final DateTime? issuedAt;

  const StationCashTicketSummary({
    required this.id,
    required this.reference,
    required this.status,
    this.seatNumber,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    required this.amount,
    required this.currency,
    this.issuedAt,
  });

  String get travelerFullName {
    return [travelerFirstname, travelerLastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  String get seatLabel =>
      seatNumber == null ? 'Placement gare' : 'Siège $seatNumber';

  factory StationCashTicketSummary.fromJson(JsonMap json) {
    return StationCashTicketSummary(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      seatNumber: _readNullableInt(json['seat_number']),
      travelerLastname: _readNullableString(json['traveler_lastname']),
      travelerFirstname: _readNullableString(json['traveler_firstname']),
      travelerPhone: _readNullableString(json['traveler_phone']),
      amount: _readString(json['amount']),
      currency: _readString(json['currency']),
      issuedAt: _readDateTime(json['issued_at']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> _readList(dynamic value) => value is List ? value : const [];

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
