class ClientTrip {
  final String id;
  final TripTicketRef ticket;
  final TripReservationRef? reservation;
  final TripStatusRef status;
  final TripTravelerRef traveler;
  final TripInfo trip;
  final TripPaymentInfo payment;
  final TripActions actions;
  final TripLinks links;
  final DateTime? issuedAt;
  final DateTime? usedAt;

  const ClientTrip({
    required this.id,
    required this.ticket,
    this.reservation,
    required this.status,
    required this.traveler,
    required this.trip,
    required this.payment,
    required this.actions,
    required this.links,
    this.issuedAt,
    this.usedAt,
  });

  bool get canOpenDigitalTicket => actions.canOpenDigitalTicket;
  bool get canDownloadPdf => actions.canDownloadPdf;
  bool get hasSeat => trip.seatNumber != null;
  String get seatDisplayLabel =>
      hasSeat ? 'Siège ${trip.seatNumber}' : 'Placement effectué à la gare';
  String get serviceClassLabel => trip.serviceClass ?? '';
  String get statusLabel =>
      status.label.isNotEmpty ? status.label : status.code;
  DateTime? get departureDate => _readDate(trip.departureDate);
  DateTime? get localIssuedAt => issuedAt?.toLocal();

  bool get isUpcoming {
    if (status.code != 'issued') return false;
    final date = departureDate;
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !date.isBefore(today);
  }

  bool get isHistory => !isUpcoming;

  factory ClientTrip.fromJson(Map<String, dynamic> json) {
    return ClientTrip(
      id: _readString(json['id']) ?? '',
      ticket: TripTicketRef.fromJson(_readMap(json['ticket'])),
      reservation: json['reservation'] == null
          ? null
          : TripReservationRef.fromJson(_readMap(json['reservation'])),
      status: TripStatusRef.fromJson(_readMap(json['status'])),
      traveler: TripTravelerRef.fromJson(_readMap(json['traveler'])),
      trip: TripInfo.fromJson(_readMap(json['trip'])),
      payment: TripPaymentInfo.fromJson(_readMap(json['payment'])),
      actions: TripActions.fromJson(_readMap(json['actions'])),
      links: TripLinks.fromJson(_readMap(json['links'])),
      issuedAt: _readDate(json['issued_at']),
      usedAt: _readDate(json['used_at']),
    );
  }
}

class TripTicketRef {
  final String id;
  final String reference;

  const TripTicketRef({required this.id, required this.reference});

  factory TripTicketRef.fromJson(Map<String, dynamic> json) {
    return TripTicketRef(
      id: _readString(json['id']) ?? '',
      reference: _readString(json['reference']) ?? '',
    );
  }
}

class TripReservationRef {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;

  const TripReservationRef({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
  });

  factory TripReservationRef.fromJson(Map<String, dynamic> json) {
    return TripReservationRef(
      id: _readString(json['id']) ?? '',
      reference: _readString(json['reference']) ?? '',
      status: _readString(json['status']) ?? '',
      statusLabel: _readString(json['status_label']) ?? '',
    );
  }
}

class TripStatusRef {
  final String code;
  final String label;

  const TripStatusRef({required this.code, required this.label});

  factory TripStatusRef.fromJson(Map<String, dynamic> json) {
    return TripStatusRef(
      code: _readString(json['code']) ?? '',
      label: _readString(json['label']) ?? '',
    );
  }
}

class TripTravelerRef {
  final String? fullName;
  final String? phone;

  const TripTravelerRef({this.fullName, this.phone});

  factory TripTravelerRef.fromJson(Map<String, dynamic> json) {
    return TripTravelerRef(
      fullName: _readString(json['full_name']),
      phone: _readString(json['phone']),
    );
  }
}

class TripInfo {
  final String? departureId;
  final String? departureStatus;
  final String? departureStatusLabel;
  final String? departureStation;
  final String? destination;
  final String? routeLabel;
  final String? departureDate;
  final String? departureTime;
  final String? serviceClass;
  final int? seatNumber;

  const TripInfo({
    this.departureId,
    this.departureStatus,
    this.departureStatusLabel,
    this.departureStation,
    this.destination,
    this.routeLabel,
    this.departureDate,
    this.departureTime,
    this.serviceClass,
    this.seatNumber,
  });

  factory TripInfo.fromJson(Map<String, dynamic> json) {
    return TripInfo(
      departureId: _readString(json['departure_id']),
      departureStatus: _readString(json['departure_status']),
      departureStatusLabel: _readString(json['departure_status_label']),
      departureStation: _readString(json['departure_station']),
      destination: _readString(json['destination']),
      routeLabel: _readString(json['route_label']),
      departureDate: _readString(json['departure_date']),
      departureTime: _readString(json['departure_time']),
      serviceClass: _readString(json['service_class']),
      seatNumber: _readInt(json['seat_number']),
    );
  }
}

class TripPaymentInfo {
  final String? amount;
  final String currency;
  final String? displayAmount;

  const TripPaymentInfo({
    this.amount,
    this.currency = 'XOF',
    this.displayAmount,
  });

  factory TripPaymentInfo.fromJson(Map<String, dynamic> json) {
    return TripPaymentInfo(
      amount: _readString(json['amount']),
      currency: _readString(json['currency']) ?? 'XOF',
      displayAmount: _readString(json['display_amount']),
    );
  }
}

class TripActions {
  final bool canOpenDigitalTicket;
  final bool canDownloadPdf;

  const TripActions({
    this.canOpenDigitalTicket = false,
    this.canDownloadPdf = false,
  });

  factory TripActions.fromJson(Map<String, dynamic> json) {
    return TripActions(
      canOpenDigitalTicket: _readBool(json['can_open_digital_ticket']),
      canDownloadPdf: _readBool(json['can_download_pdf']),
    );
  }
}

class TripLinks {
  final String? digitalTicket;
  final String? downloadPdf;

  const TripLinks({this.digitalTicket, this.downloadPdf});

  factory TripLinks.fromJson(Map<String, dynamic> json) {
    return TripLinks(
      digitalTicket: _readString(json['digital_ticket']),
      downloadPdf: _readString(json['download_pdf']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String? _readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
