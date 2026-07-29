class ReservationItemDetail {
  final String id;
  final String status;
  final String? departureId;
  final String? departureSeatId;
  final String? seatHoldId;
  final int? seatNumber;
  final String? seatNumberSnapshot;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final String unitPrice;
  final String currency;
  final String? serviceClassCode;
  final String? serviceClassName;
  final String? routeLabel;
  final String? departureDate;
  final String? departureTime;
  final String? stationName;
  final String? destinationName;

  const ReservationItemDetail({
    required this.id,
    required this.status,
    this.departureId,
    this.departureSeatId,
    this.seatHoldId,
    this.seatNumber,
    this.seatNumberSnapshot,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    required this.unitPrice,
    required this.currency,
    this.serviceClassCode,
    this.serviceClassName,
    this.routeLabel,
    this.departureDate,
    this.departureTime,
    this.stationName,
    this.destinationName,
  });

  bool get hasSeat =>
      seatNumber != null ||
      (seatNumberSnapshot != null && seatNumberSnapshot!.isNotEmpty);

  String get travelerFullName {
    final parts = [travelerFirstname, travelerLastname]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Voyageur' : parts.join(' ');
  }

  String get seatDisplayLabel {
    if (seatNumber != null) return 'Siege $seatNumber';
    if (seatNumberSnapshot != null && seatNumberSnapshot!.isNotEmpty) {
      return 'Siege $seatNumberSnapshot';
    }
    return 'Placement effectue a la gare';
  }

  factory ReservationItemDetail.fromJson(Map<String, dynamic> json) {
    final seatNumber = _readInt(
      json['seat_number'] ?? json['seat_number_snapshot'],
    );

    return ReservationItemDetail(
      id: _readString(json['id']) ?? '',
      status: _readString(json['status']) ?? '',
      departureId: _readId(json['departure']),
      departureSeatId: _readId(json['departure_seat']),
      seatHoldId: _readId(json['seat_hold']),
      seatNumber: seatNumber,
      seatNumberSnapshot:
          _readString(json['seat_number_snapshot']) ?? seatNumber?.toString(),
      travelerLastname: _readString(
        json['traveler_lastname'] ?? json['traveler_lastname_snapshot'],
      ),
      travelerFirstname: _readString(
        json['traveler_firstname'] ?? json['traveler_firstname_snapshot'],
      ),
      travelerPhone: _readString(
        json['traveler_phone'] ?? json['traveler_phone_snapshot'],
      ),
      unitPrice: _readAmount(json['unit_price']),
      currency: _readString(json['currency']) ?? 'XOF',
      serviceClassCode: _readNestedString(
            json['service_class'],
            ['code'],
          ) ??
          _readString(json['service_class_code']),
      serviceClassName: _readNestedString(
            json['service_class'],
            ['name'],
          ) ??
          _readString(json['service_class_name']),
      routeLabel: _readNestedString(
            json['route'],
            ['label', 'name'],
          ) ??
          _readString(json['route_label']),
      departureDate: _readNestedString(
            json['departure'],
            ['departure_date'],
          ) ??
          _readString(json['departure_date']),
      departureTime: _readNestedString(
            json['departure'],
            ['departure_time', 'departure_time_raw'],
          ) ??
          _readString(json['departure_time']),
      stationName: _readNestedString(
            json['departure'],
            ['station_name'],
          ) ??
          _readNestedString(json['station'], ['name']) ??
          _readString(json['station_name']),
      destinationName: _readNestedString(
            json['departure'],
            ['destination_name', 'destination'],
          ) ??
          _readNestedString(json['destination'], ['name']) ??
          _readString(json['destination_name']),
    );
  }

  static String _readAmount(dynamic value) {
    if (value == null) return '0.00';
    if (value is num) return value.toStringAsFixed(2);
    return value.toString();
  }

  static String? _readId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return _readString(value['id']);
    return value.toString();
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _readNestedString(dynamic source, List<String> keys) {
    if (source is! Map) return null;
    for (final key in keys) {
      final value = _readString(source[key]);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
