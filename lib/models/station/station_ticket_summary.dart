class StationTicketSummary {
  final String? id;
  final String? reference;
  final String? status;

  const StationTicketSummary({
    this.id,
    this.reference,
    this.status,
  });

  bool get isAvailable => id != null && id!.isNotEmpty;
}

class StationTicketPrintResponse {
  final String printType;
  final StationTicketPrint ticket;

  const StationTicketPrintResponse({
    required this.printType,
    required this.ticket,
  });

  factory StationTicketPrintResponse.fromJson(Map<String, dynamic> json) {
    final ticketJson = json['ticket'];
    return StationTicketPrintResponse(
      printType: json['print_type']?.toString() ?? '',
      ticket: StationTicketPrint.fromJson(
        ticketJson is Map ? Map<String, dynamic>.from(ticketJson) : const {},
      ),
    );
  }
}

class StationTicketPrint {
  final String id;
  final String reference;
  final String reservationReference;
  final String status;
  final String travelerLastname;
  final String travelerFirstname;
  final String travelerPhone;
  final int? seatNumber;
  final String amount;
  final String currency;
  final String? departureDate;
  final String? departureTime;
  final String? stationName;
  final String? destinationName;
  final String? serviceClassName;
  final String validationToken;
  final DateTime? issuedAt;

  const StationTicketPrint({
    required this.id,
    required this.reference,
    required this.reservationReference,
    required this.status,
    required this.travelerLastname,
    required this.travelerFirstname,
    required this.travelerPhone,
    this.seatNumber,
    required this.amount,
    required this.currency,
    this.departureDate,
    this.departureTime,
    this.stationName,
    this.destinationName,
    this.serviceClassName,
    required this.validationToken,
    this.issuedAt,
  });

  String get travelerFullName => '$travelerFirstname $travelerLastname'.trim();
  String get displayAmount => '$amount $currency'.trim();
  String get tripLabel => [stationName, destinationName]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' → ');

  factory StationTicketPrint.fromJson(Map<String, dynamic> json) {
    return StationTicketPrint(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      reservationReference: json['reservation_reference']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      travelerLastname: json['traveler_lastname']?.toString() ?? '',
      travelerFirstname: json['traveler_firstname']?.toString() ?? '',
      travelerPhone: json['traveler_phone']?.toString() ?? '',
      seatNumber: _readNullableInt(json['seat_number']),
      amount: json['amount']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      departureDate: _readNullableString(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      stationName: _readNullableString(json['station_name']),
      destinationName: _readNullableString(json['destination_name']),
      serviceClassName: _readNullableString(json['service_class_name']),
      validationToken: json['validation_token']?.toString() ?? '',
      issuedAt: _parseDateTime(json['issued_at']),
    );
  }
}

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
