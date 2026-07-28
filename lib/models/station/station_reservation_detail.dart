import 'package:catrans_app/models/station/station_payment_summary.dart';
import 'package:catrans_app/models/station/station_ticket_summary.dart';

class StationReservationDetail {
  final String id;
  final String reference;
  final String status;
  final String? customer;
  final String? createdBy;
  final String channel;
  final String? customerPhone;
  final String? customerLastname;
  final String? customerFirstname;
  final String? customerFullName;
  final String totalAmount;
  final String currency;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final List<StationReservationItemDetail> items;
  final List<StationPaymentSummary> payments;

  const StationReservationDetail({
    required this.id,
    required this.reference,
    required this.status,
    this.customer,
    this.createdBy,
    required this.channel,
    this.customerPhone,
    this.customerLastname,
    this.customerFirstname,
    this.customerFullName,
    required this.totalAmount,
    required this.currency,
    this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    this.createdAt,
    required this.items,
    required this.payments,
  });

  String get displayCustomerName {
    final fullName = customerFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return [customerFirstname, customerLastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  String get displayAmount => '$totalAmount $currency'.trim();

  StationReservationItemDetail? get firstTicketItem {
    for (final item in items) {
      if (item.hasTicket) return item;
    }
    return null;
  }

  bool get hasTicket => firstTicketItem != null;

  factory StationReservationDetail.fromJson(Map<String, dynamic> json) {
    return StationReservationDetail(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      customer: _readNullableString(json['customer']),
      createdBy: _readNullableString(json['created_by']),
      channel: _readString(json['channel']),
      customerPhone: _readNullableString(json['customer_phone_snapshot']),
      customerLastname: _readNullableString(json['customer_lastname_snapshot']),
      customerFirstname:
          _readNullableString(json['customer_firstname_snapshot']),
      customerFullName: _readNullableString(json['customer_full_name']),
      totalAmount: _readString(json['total_amount']),
      currency: _readString(json['currency']),
      expiresAt: _parseDateTime(json['expires_at']),
      confirmedAt: _parseDateTime(json['confirmed_at']),
      cancelledAt: _parseDateTime(json['cancelled_at']),
      createdAt: _parseDateTime(json['created_at']),
      items: _readList(json['items'])
          .map((item) => StationReservationItemDetail.fromJson(
                _readObject(item),
              ))
          .toList(),
      payments: _readList(json['payments'])
          .map((payment) => StationPaymentSummary.fromJson(
                _readObject(payment),
              ))
          .toList(),
    );
  }
}

class StationReservationItemDetail {
  final String id;
  final String departure;
  final String? departureSeat;
  final int? seatNumber;
  final bool isForCustomer;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final String unitPrice;
  final String currency;
  final String status;
  final String? ticketId;
  final String? ticketReference;
  final String? ticketStatus;
  final String? ticketStatusLabel;
  final DateTime? ticketUsedAt;
  final DateTime? ticketSuspendedUntil;
  final bool canEdit;
  final bool canSuspend;
  final bool canReactivate;
  final String? departureDate;
  final String? departureTime;
  final String? stationName;
  final String? destinationName;
  final String? serviceClassName;
  final String? serviceClassCode;
  final DateTime? createdAt;

  const StationReservationItemDetail({
    required this.id,
    required this.departure,
    this.departureSeat,
    this.seatNumber,
    required this.isForCustomer,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    required this.unitPrice,
    required this.currency,
    required this.status,
    this.ticketId,
    this.ticketReference,
    this.ticketStatus,
    this.ticketStatusLabel,
    this.ticketUsedAt,
    this.ticketSuspendedUntil,
    this.canEdit = false,
    this.canSuspend = false,
    this.canReactivate = false,
    this.departureDate,
    this.departureTime,
    this.stationName,
    this.destinationName,
    this.serviceClassName,
    this.serviceClassCode,
    this.createdAt,
  });

  String get travelerFullName {
    return [travelerFirstname, travelerLastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  String get displayAmount => '$unitPrice $currency'.trim();
  String get seatLabel =>
      seatNumber == null ? 'Placement gare' : 'Siège $seatNumber';
  bool get hasTicket => ticketId != null && ticketId!.isNotEmpty;
  bool get isBoarded => ticketStatus == 'used';
  bool get isSuspended => ticketSuspendedUntil != null;
  bool get usesManualSeat => seatNumber != null;

  String get tripLabel {
    final route = [stationName, destinationName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' → ');
    return route.isEmpty ? '-' : route;
  }

  StationTicketSummary get ticketSummary => StationTicketSummary(
        id: ticketId,
        reference: ticketReference,
        status: ticketStatus,
      );

  factory StationReservationItemDetail.fromJson(Map<String, dynamic> json) {
    return StationReservationItemDetail(
      id: _readString(json['id']),
      departure: _readString(json['departure']),
      departureSeat: _readNullableString(json['departure_seat']),
      seatNumber: _readNullableInt(json['seat_number']),
      isForCustomer: json['is_for_customer'] == true,
      travelerLastname: _readNullableString(json['traveler_lastname']),
      travelerFirstname: _readNullableString(json['traveler_firstname']),
      travelerPhone: _readNullableString(json['traveler_phone']),
      unitPrice: _readString(json['unit_price']),
      currency: _readString(json['currency']),
      status: _readString(json['status']),
      ticketId: _readNullableString(json['ticket_id']),
      ticketReference: _readNullableString(json['ticket_reference']),
      ticketStatus: _readNullableString(json['ticket_status']),
      ticketStatusLabel: _readNullableString(json['ticket_status_label']),
      ticketUsedAt: _parseDateTime(json['ticket_used_at']),
      ticketSuspendedUntil: _parseDateTime(json['ticket_suspended_until']),
      canEdit: json['can_edit'] == true,
      canSuspend: json['can_suspend'] == true,
      canReactivate: json['can_reactivate'] == true,
      departureDate: _readNullableString(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      stationName: _readNullableString(json['station_name']),
      destinationName: _readNullableString(json['destination_name']),
      serviceClassName: _readNullableString(json['service_class_name']),
      serviceClassCode: _readNullableString(json['service_class_code']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class StationReservationItemEditResponse {
  final String message;
  final StationReservationDetail reservation;
  final Map<String, dynamic> change;

  const StationReservationItemEditResponse({
    required this.message,
    required this.reservation,
    required this.change,
  });

  factory StationReservationItemEditResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationReservationItemEditResponse(
      message: _readString(json['message']),
      reservation: StationReservationDetail.fromJson(
        _readObject(json['reservation']),
      ),
      change: _readObject(json['change']),
    );
  }
}

class StationTicketActionResponse {
  final String message;
  final StationReservationDetail reservation;

  const StationTicketActionResponse({
    required this.message,
    required this.reservation,
  });

  factory StationTicketActionResponse.fromJson(Map<String, dynamic> json) {
    return StationTicketActionResponse(
      message: _readString(json['message']),
      reservation: StationReservationDetail.fromJson(
        _readObject(json['reservation']),
      ),
    );
  }
}

List<dynamic> _readList(dynamic value) => value is List ? value : const [];

Map<String, dynamic> _readObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
