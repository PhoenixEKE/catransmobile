import 'package:catrans_app/models/station/station_departure.dart';

class StationBoardingManifestResponse {
  final StationBoardingManifestSummary summary;
  final StationDeparture departure;
  final List<StationBoardingTicket> passengers;

  const StationBoardingManifestResponse({
    required this.summary,
    required this.departure,
    required this.passengers,
  });

  factory StationBoardingManifestResponse.fromJson(Map<String, dynamic> json) {
    return StationBoardingManifestResponse(
      summary: StationBoardingManifestSummary.fromJson(
        _readObject(json['summary']),
      ),
      departure: StationDeparture.fromJson(_readObject(json['departure'])),
      passengers: _readList(json['passengers'])
          .map((item) => StationBoardingTicket.fromJson(_readObject(item)))
          .toList(),
    );
  }
}

class StationBoardingManifestSummary {
  final int total;
  final int toBoard;
  final int boarded;
  final int notBoardable;

  const StationBoardingManifestSummary({
    required this.total,
    required this.toBoard,
    required this.boarded,
    required this.notBoardable,
  });

  factory StationBoardingManifestSummary.fromJson(Map<String, dynamic> json) {
    return StationBoardingManifestSummary(
      total: _readInt(json['total']),
      toBoard: _readInt(json['to_board']),
      boarded: _readInt(json['boarded']),
      notBoardable: _readInt(json['not_boardable']),
    );
  }
}

class StationBoardingTicket {
  final String id;
  final String reference;
  final String statusCode;
  final String statusLabel;
  final String? reservationId;
  final String? reservationReference;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerFullName;
  final String? travelerPhone;
  final int? seatNumber;
  final String? serviceClass;
  final String? destination;
  final String? departureDate;
  final String? departureTime;
  final bool canBoard;
  final bool isBoarded;
  final String? boardingMessage;
  final DateTime? boardedAt;
  final DateTime? issuedAt;
  final DateTime? usedAt;

  const StationBoardingTicket({
    required this.id,
    required this.reference,
    required this.statusCode,
    required this.statusLabel,
    this.reservationId,
    this.reservationReference,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerFullName,
    this.travelerPhone,
    this.seatNumber,
    this.serviceClass,
    this.destination,
    this.departureDate,
    this.departureTime,
    required this.canBoard,
    required this.isBoarded,
    this.boardingMessage,
    this.boardedAt,
    this.issuedAt,
    this.usedAt,
  });

  String get displayTraveler {
    final name = travelerFullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return [travelerFirstname, travelerLastname]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
  }

  String get displaySeat =>
      seatNumber == null ? 'Placement gare' : 'Siège $seatNumber';

  factory StationBoardingTicket.fromJson(Map<String, dynamic> json) {
    final status = _readObject(json['status']);
    final traveler = _readObject(json['traveler']);
    final seat = _readObject(json['seat']);
    final trip = _readObject(json['trip']);
    final boarding = _readObject(json['boarding']);

    return StationBoardingTicket(
      id: _readString(json['id'] ?? json['ticket_id']),
      reference: _readString(json['reference'] ?? json['ticket_reference']),
      statusCode: _readString(status['code'] ?? json['status']),
      statusLabel: _readString(status['label'] ?? json['status_label']),
      reservationId: _readNullableString(json['reservation']),
      reservationReference: _readNullableString(json['reservation_reference']),
      travelerLastname: _readNullableString(
          traveler['lastname'] ?? json['traveler_lastname']),
      travelerFirstname: _readNullableString(
          traveler['firstname'] ?? json['traveler_firstname']),
      travelerFullName: _readNullableString(traveler['full_name']),
      travelerPhone:
          _readNullableString(traveler['phone'] ?? json['traveler_phone']),
      seatNumber: _readNullableInt(seat['number'] ?? json['seat_number']),
      serviceClass: _readNullableString(trip['service_class']),
      destination: _readNullableString(trip['destination']),
      departureDate: _readNullableString(trip['date']),
      departureTime: _readNullableString(trip['time']),
      canBoard: boarding['can_board'] == true,
      isBoarded: boarding['is_boarded'] == true || json['status'] == 'used',
      boardingMessage: _readNullableString(boarding['message']),
      boardedAt: _parseDateTime(boarding['boarded_at']),
      issuedAt: _parseDateTime(json['issued_at']),
      usedAt: _parseDateTime(json['used_at']),
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

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
