class TicketDigital {
  final String id;
  final String reference;
  final TicketReservationRef? reservation;
  final TicketStatusRef status;
  final TicketTraveler traveler;
  final TicketTripInfo trip;
  final TicketPaymentInfo payment;
  final TicketQrInfo qr;
  final TicketPhysicalPickupInfo physicalTicketPickup;
  final TicketActions actions;
  final DateTime? issuedAt;
  final DateTime? usedAt;

  const TicketDigital({
    required this.id,
    required this.reference,
    this.reservation,
    required this.status,
    required this.traveler,
    required this.trip,
    required this.payment,
    required this.qr,
    required this.physicalTicketPickup,
    required this.actions,
    this.issuedAt,
    this.usedAt,
  });

  bool get hasSeat => trip.seatNumber != null;
  String get seatDisplayLabel =>
      hasSeat ? 'Siège ${trip.seatNumber}' : 'Placement effectué à la gare';
  bool get hasQrValue => qr.value.trim().isNotEmpty;
  bool get canDownloadPdf => actions.canDownloadPdf;
  bool get isIssued => status.code == 'issued';
  bool get isUsed => status.code == 'used';
  bool get isCancelled => status.code == 'cancelled';
  bool get isExpired => status.code == 'expired';
  DateTime? get localIssuedAt => issuedAt?.toLocal();
  DateTime? get localUsedAt => usedAt?.toLocal();

  factory TicketDigital.fromJson(Map<String, dynamic> json) {
    return TicketDigital(
      id: _readString(json['id']) ?? '',
      reference: _readString(json['reference']) ?? '',
      reservation: json['reservation'] == null
          ? null
          : TicketReservationRef.fromJson(_readMap(json['reservation'])),
      status: TicketStatusRef.fromJson(_readMap(json['status'])),
      traveler: TicketTraveler.fromJson(_readMap(json['traveler'])),
      trip: TicketTripInfo.fromJson(_readMap(json['trip'])),
      payment: TicketPaymentInfo.fromJson(_readMap(json['payment'])),
      qr: TicketQrInfo.fromJson(_readMap(json['qr'])),
      physicalTicketPickup: TicketPhysicalPickupInfo.fromJson(
        _readMap(json['physical_ticket_pickup']),
      ),
      actions: TicketActions.fromJson(_readMap(json['actions'])),
      issuedAt: _readDate(json['issued_at']),
      usedAt: _readDate(json['used_at']),
    );
  }
}

class TicketReservationRef {
  final String id;
  final String reference;

  const TicketReservationRef({required this.id, required this.reference});

  factory TicketReservationRef.fromJson(Map<String, dynamic> json) {
    return TicketReservationRef(
      id: _readString(json['id']) ?? '',
      reference: _readString(json['reference']) ?? '',
    );
  }
}

class TicketStatusRef {
  final String code;
  final String label;

  const TicketStatusRef({required this.code, required this.label});

  factory TicketStatusRef.fromJson(Map<String, dynamic> json) {
    return TicketStatusRef(
      code: _readString(json['code']) ?? '',
      label: _readString(json['label']) ?? '',
    );
  }
}

class TicketTraveler {
  final String? lastname;
  final String? firstname;
  final String? fullName;
  final String? phone;

  const TicketTraveler({
    this.lastname,
    this.firstname,
    this.fullName,
    this.phone,
  });

  factory TicketTraveler.fromJson(Map<String, dynamic> json) {
    return TicketTraveler(
      lastname: _readString(json['lastname']),
      firstname: _readString(json['firstname']),
      fullName: _readString(json['full_name']),
      phone: _readString(json['phone']),
    );
  }
}

class TicketTripInfo {
  final String? departureId;
  final String? departureStation;
  final String? destination;
  final String? departureDate;
  final String? departureTime;
  final String? routeLabel;
  final String? serviceClass;
  final int? seatNumber;

  const TicketTripInfo({
    this.departureId,
    this.departureStation,
    this.destination,
    this.departureDate,
    this.departureTime,
    this.routeLabel,
    this.serviceClass,
    this.seatNumber,
  });

  DateTime? get parsedDepartureDate => _readDate(departureDate);

  factory TicketTripInfo.fromJson(Map<String, dynamic> json) {
    return TicketTripInfo(
      departureId: _readString(json['departure_id']),
      departureStation: _readString(json['departure_station']),
      destination: _readString(json['destination']),
      departureDate: _readString(json['departure_date']),
      departureTime: _readString(json['departure_time']),
      routeLabel: _readString(json['route_label']),
      serviceClass: _readString(json['service_class']),
      seatNumber: _readInt(json['seat_number']),
    );
  }
}

class TicketPaymentInfo {
  final String? amount;
  final String currency;
  final String? displayAmount;

  const TicketPaymentInfo({
    this.amount,
    this.currency = 'XOF',
    this.displayAmount,
  });

  factory TicketPaymentInfo.fromJson(Map<String, dynamic> json) {
    return TicketPaymentInfo(
      amount: _readString(json['amount']),
      currency: _readString(json['currency']) ?? 'XOF',
      displayAmount: _readString(json['display_amount']),
    );
  }
}

class TicketQrInfo {
  final String type;
  final String value;
  final String? instruction;

  const TicketQrInfo({
    required this.type,
    required this.value,
    this.instruction,
  });

  factory TicketQrInfo.fromJson(Map<String, dynamic> json) {
    return TicketQrInfo(
      type: _readString(json['type']) ?? '',
      value: _readString(json['value']) ?? '',
      instruction: _readString(json['instruction']),
    );
  }
}

class TicketPhysicalPickupInfo {
  final int? minutesBeforeDeparture;
  final DateTime? deadlineAt;
  final String? message;

  const TicketPhysicalPickupInfo({
    this.minutesBeforeDeparture,
    this.deadlineAt,
    this.message,
  });

  DateTime? get localDeadlineAt => deadlineAt?.toLocal();

  factory TicketPhysicalPickupInfo.fromJson(Map<String, dynamic> json) {
    return TicketPhysicalPickupInfo(
      minutesBeforeDeparture: _readInt(json['minutes_before_departure']),
      deadlineAt: _readDate(json['deadline_at']),
      message: _readString(json['message']),
    );
  }
}

class TicketActions {
  final bool canDownloadPdf;
  final bool canShare;
  final bool canRequestChange;
  final bool canRequestCancellation;

  const TicketActions({
    this.canDownloadPdf = false,
    this.canShare = false,
    this.canRequestChange = false,
    this.canRequestCancellation = false,
  });

  factory TicketActions.fromJson(Map<String, dynamic> json) {
    return TicketActions(
      canDownloadPdf: _readBool(json['can_download_pdf']),
      canShare: _readBool(json['can_share']),
      canRequestChange: _readBool(json['can_request_change']),
      canRequestCancellation: _readBool(json['can_request_cancellation']),
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
