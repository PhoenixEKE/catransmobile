class StationSearchResponse {
  final String query;
  final List<StationSearchReservation> reservations;
  final List<StationSearchTicket> tickets;

  const StationSearchResponse({
    required this.query,
    required this.reservations,
    required this.tickets,
  });

  bool get isEmpty => reservations.isEmpty && tickets.isEmpty;

  factory StationSearchResponse.fromJson(Map<String, dynamic> json) {
    return StationSearchResponse(
      query: _readString(json['query']),
      reservations: _readList(json['reservations'])
          .map((item) => StationSearchReservation.fromJson(_readObject(item)))
          .toList(),
      tickets: _readList(json['tickets'])
          .map((item) => StationSearchTicket.fromJson(_readObject(item)))
          .toList(),
    );
  }
}

class StationSearchReservation {
  final String id;
  final String reference;
  final String status;
  final String? customerPhone;
  final String? customerLastname;
  final String? customerFirstname;
  final String? customerFullName;
  final String totalAmount;
  final String currency;
  final int itemsCount;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const StationSearchReservation({
    required this.id,
    required this.reference,
    required this.status,
    this.customerPhone,
    this.customerLastname,
    this.customerFirstname,
    this.customerFullName,
    required this.totalAmount,
    required this.currency,
    required this.itemsCount,
    this.createdAt,
    this.confirmedAt,
  });

  String get displayCustomerName {
    final fullName = customerFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return [customerFirstname, customerLastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  String get displayAmount => '$totalAmount $currency'.trim();

  factory StationSearchReservation.fromJson(Map<String, dynamic> json) {
    return StationSearchReservation(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      customerPhone: _readNullableString(json['customer_phone_snapshot']),
      customerLastname: _readNullableString(json['customer_lastname_snapshot']),
      customerFirstname: _readNullableString(json['customer_firstname_snapshot']),
      customerFullName: _readNullableString(json['customer_full_name']),
      totalAmount: _readString(json['total_amount']),
      currency: _readString(json['currency']),
      itemsCount: _readInt(json['items_count']),
      createdAt: _parseDateTime(json['created_at']),
      confirmedAt: _parseDateTime(json['confirmed_at']),
    );
  }
}

class StationSearchTicket {
  final String id;
  final String reference;
  final String reservationId;
  final String reservationReference;
  final String status;
  final String statusLabel;
  final String travelerLastname;
  final String travelerFirstname;
  final String travelerPhone;
  final int? seatNumber;
  final String? departureDate;
  final String? departureTime;
  final String? stationName;
  final String? destinationName;
  final String? serviceClassName;
  final DateTime? issuedAt;
  final DateTime? usedAt;

  const StationSearchTicket({
    required this.id,
    required this.reference,
    required this.reservationId,
    required this.reservationReference,
    required this.status,
    required this.statusLabel,
    required this.travelerLastname,
    required this.travelerFirstname,
    required this.travelerPhone,
    this.seatNumber,
    this.departureDate,
    this.departureTime,
    this.stationName,
    this.destinationName,
    this.serviceClassName,
    this.issuedAt,
    this.usedAt,
  });

  String get travelerFullName => '$travelerFirstname $travelerLastname'.trim();
  String get tripLabel => [stationName, destinationName]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' → ');

  factory StationSearchTicket.fromJson(Map<String, dynamic> json) {
    return StationSearchTicket(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      reservationId: _readString(json['reservation']),
      reservationReference: _readString(json['reservation_reference']),
      status: _readString(json['status']),
      statusLabel: _readString(json['status_label']),
      travelerLastname: _readString(json['traveler_lastname']),
      travelerFirstname: _readString(json['traveler_firstname']),
      travelerPhone: _readString(json['traveler_phone']),
      seatNumber: _readNullableInt(json['seat_number']),
      departureDate: _readNullableString(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      stationName: _readNullableString(json['station_name']),
      destinationName: _readNullableString(json['destination_name']),
      serviceClassName: _readNullableString(json['service_class_name']),
      issuedAt: _parseDateTime(json['issued_at']),
      usedAt: _parseDateTime(json['used_at']),
    );
  }
}

class StationCustomerSearchResult {
  final String customerId;
  final String phoneNumber;
  final String firstname;
  final String lastname;
  final String displayName;

  const StationCustomerSearchResult({
    required this.customerId,
    required this.phoneNumber,
    required this.firstname,
    required this.lastname,
    required this.displayName,
  });

  factory StationCustomerSearchResult.fromJson(Map<String, dynamic> json) {
    return StationCustomerSearchResult(
      customerId: _readString(json['customer_id']),
      phoneNumber: _readString(json['phone_number']),
      firstname: _readString(json['firstname']),
      lastname: _readString(json['lastname']),
      displayName: _readString(json['display_name']),
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

int _readInt(dynamic value) => _readNullableInt(value) ?? 0;

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
