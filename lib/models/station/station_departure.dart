class StationDeparture {
  final String id;
  final String statusCode;
  final String statusLabel;
  final String? stationId;
  final String? stationName;
  final String? routeId;
  final String? destinationName;
  final String departureDate;
  final String? departureTime;
  final String? departureTimeRaw;
  final String? departureTimeDisplay;
  final String? serviceClassId;
  final String? serviceClassCode;
  final String? serviceClassName;
  final String? seatLayoutId;
  final StationDepartureSeatSummary seats;
  final StationDepartureTicketSummary tickets;
  final int validationsTotal;
  final int validationsAccepted;
  final int validationsRejected;

  const StationDeparture({
    required this.id,
    required this.statusCode,
    required this.statusLabel,
    this.stationId,
    this.stationName,
    this.routeId,
    this.destinationName,
    required this.departureDate,
    this.departureTime,
    this.departureTimeRaw,
    this.departureTimeDisplay,
    this.serviceClassId,
    this.serviceClassCode,
    this.serviceClassName,
    this.seatLayoutId,
    required this.seats,
    required this.tickets,
    this.validationsTotal = 0,
    this.validationsAccepted = 0,
    this.validationsRejected = 0,
  });

  String get routeLabel => [stationName, destinationName]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' → ');

  String get displayTime {
    final value = departureTimeDisplay ?? departureTimeRaw ?? departureTime;
    return value == null || value.isEmpty ? '-' : value;
  }

  String get displayDateTime {
    final date = departureDate.isEmpty ? '-' : departureDate;
    return '$date à $displayTime';
  }

  factory StationDeparture.fromJson(Map<String, dynamic> json) {
    final status = _readObject(json['status']);
    final station = _readObject(json['station']);
    final route = _readObject(json['route']);
    final destination = _readObject(json['destination']);
    final serviceClass = _readObject(json['service_class']);
    final seatLayout = _readObject(json['seat_layout']);
    final seatsObject = _readObject(json['seats']);
    final ticketsObject = _readObject(json['tickets']);

    return StationDeparture(
      id: _readString(json['id']),
      statusCode: _readString(status['code'] ?? json['status']),
      statusLabel: _readString(status['label'] ?? json['status_label']),
      stationId: _readNullableString(station['id'] ?? json['station']),
      stationName: _readNullableString(station['name'] ?? json['station_name']),
      routeId: _readNullableString(route['id'] ?? json['route']),
      destinationName: _readNullableString(
        destination['name'] ?? json['destination_name'] ?? json['destination'],
      ),
      departureDate: _readString(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      departureTimeRaw: _readNullableString(json['departure_time_raw']),
      departureTimeDisplay: _readNullableString(json['departure_time_display']),
      serviceClassId: _readNullableString(
        serviceClass['id'] ?? json['service_class'],
      ),
      serviceClassCode: _readNullableString(serviceClass['code']),
      serviceClassName: _readNullableString(
        serviceClass['name'] ?? json['service_class_name'],
      ),
      seatLayoutId:
          _readNullableString(seatLayout['id'] ?? json['seat_layout']),
      seats: seatsObject.isNotEmpty
          ? StationDepartureSeatSummary.fromJson(seatsObject)
          : StationDepartureSeatSummary.fromFlatJson(json),
      tickets: ticketsObject.isNotEmpty
          ? StationDepartureTicketSummary.fromJson(ticketsObject)
          : StationDepartureTicketSummary.fromFlatJson(json),
      validationsTotal: _readInt(json['validations_total']),
      validationsAccepted: _readInt(json['validations_accepted']),
      validationsRejected: _readInt(json['validations_rejected']),
    );
  }
}

class StationDepartureSeatSummary {
  final int total;
  final int available;
  final int held;
  final int reserved;
  final int blocked;

  const StationDepartureSeatSummary({
    required this.total,
    required this.available,
    required this.held,
    required this.reserved,
    required this.blocked,
  });

  factory StationDepartureSeatSummary.fromJson(Map<String, dynamic> json) {
    return StationDepartureSeatSummary(
      total: _readInt(json['total']),
      available: _readInt(json['available']),
      held: _readInt(json['held']),
      reserved: _readInt(json['reserved']),
      blocked: _readInt(json['blocked']),
    );
  }

  factory StationDepartureSeatSummary.fromFlatJson(Map<String, dynamic> json) {
    return StationDepartureSeatSummary(
      total: _readInt(json['total_seats']),
      available: _readInt(json['available_seats']),
      held: _readInt(json['held_seats']),
      reserved: _readInt(json['reserved_seats']),
      blocked: _readInt(json['blocked_seats']),
    );
  }
}

class StationDepartureTicketSummary {
  final int total;
  final int issued;
  final int used;
  final int cancelled;
  final int expired;

  const StationDepartureTicketSummary({
    required this.total,
    required this.issued,
    required this.used,
    required this.cancelled,
    required this.expired,
  });

  int get remaining {
    final value = total - used - cancelled - expired;
    return value < 0 ? 0 : value;
  }

  factory StationDepartureTicketSummary.fromJson(Map<String, dynamic> json) {
    return StationDepartureTicketSummary(
      total: _readInt(json['total']),
      issued: _readInt(json['issued']),
      used: _readInt(json['used']),
      cancelled: _readInt(json['cancelled']),
      expired: _readInt(json['expired']),
    );
  }

  factory StationDepartureTicketSummary.fromFlatJson(
      Map<String, dynamic> json) {
    return StationDepartureTicketSummary(
      total: _readInt(json['tickets_total']),
      issued: _readInt(json['tickets_issued']),
      used: _readInt(json['tickets_used']),
      cancelled: _readInt(json['tickets_cancelled']),
      expired: _readInt(json['tickets_expired']),
    );
  }
}

Map<String, dynamic> _readObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
