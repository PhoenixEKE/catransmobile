class StationTicketValidation {
  final String id;
  final String? ticketId;
  final String? ticketReference;
  final String? scannedToken;
  final String status;
  final String statusLabel;
  final String channel;
  final String channelLabel;
  final String? departureId;
  final String? deviceIdentifier;
  final String? resultMessage;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;
  final int? seatNumber;
  final String? departureDate;
  final String? departureTime;
  final String? stationName;
  final String? destinationName;
  final String? serviceClassName;
  final DateTime? validatedAt;

  const StationTicketValidation({
    required this.id,
    this.ticketId,
    this.ticketReference,
    this.scannedToken,
    required this.status,
    required this.statusLabel,
    required this.channel,
    required this.channelLabel,
    this.departureId,
    this.deviceIdentifier,
    this.resultMessage,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
    this.seatNumber,
    this.departureDate,
    this.departureTime,
    this.stationName,
    this.destinationName,
    this.serviceClassName,
    this.validatedAt,
  });

  bool get isAccepted => status == 'accepted';

  String get travelerFullName => [travelerFirstname, travelerLastname]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' ');

  String get displaySeat =>
      seatNumber == null ? 'Placement gare' : 'Siège $seatNumber';

  factory StationTicketValidation.fromJson(Map<String, dynamic> json) {
    return StationTicketValidation(
      id: _readString(json['id']),
      ticketId: _readNullableString(json['ticket']),
      ticketReference: _readNullableString(json['ticket_reference']),
      scannedToken: _readNullableString(json['scanned_token']),
      status: _readString(json['status']),
      statusLabel: _readString(json['status_label']),
      channel: _readString(json['channel']),
      channelLabel: _readString(json['channel_label']),
      departureId: _readNullableString(json['departure']),
      deviceIdentifier: _readNullableString(json['device_identifier']),
      resultMessage: _readNullableString(json['result_message']),
      travelerLastname: _readNullableString(json['traveler_lastname']),
      travelerFirstname: _readNullableString(json['traveler_firstname']),
      travelerPhone: _readNullableString(json['traveler_phone']),
      seatNumber: _readNullableInt(json['seat_number']),
      departureDate: _readNullableString(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      stationName: _readNullableString(json['station_name']),
      destinationName: _readNullableString(json['destination_name']),
      serviceClassName: _readNullableString(json['service_class_name']),
      validatedAt: _parseDateTime(json['validated_at']),
    );
  }
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
