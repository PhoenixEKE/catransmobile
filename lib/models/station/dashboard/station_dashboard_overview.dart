class StationDashboardOverview {
  final DateTime? date;
  final DateTime? generatedAt;
  final StationDashboardStation station;
  final StationDashboardSummary summary;
  final List<StationDashboardDeparture> upcomingDepartures;
  final List<StationDashboardAlert> alerts;
  final StationDashboardPendingRequests pendingRequests;
  final StationDashboardCapabilities capabilities;

  const StationDashboardOverview({
    required this.date,
    required this.generatedAt,
    required this.station,
    required this.summary,
    required this.upcomingDepartures,
    required this.alerts,
    required this.pendingRequests,
    required this.capabilities,
  });

  factory StationDashboardOverview.fromJson(Map<String, dynamic> json) {
    return StationDashboardOverview(
      date: _readDate(json['date']),
      generatedAt: _readDateTime(json['generated_at']),
      station: StationDashboardStation.fromJson(_readMap(json['station'])),
      summary: StationDashboardSummary.fromJson(_readMap(json['summary'])),
      upcomingDepartures: _readList(json['upcoming_departures'])
          .map(StationDashboardDeparture.fromJson)
          .toList(),
      alerts: _readList(json['alerts'])
          .map(StationDashboardAlert.fromJson)
          .toList(),
      pendingRequests: StationDashboardPendingRequests.fromJson(
        _readMap(json['pending_requests']),
      ),
      capabilities: StationDashboardCapabilities.fromJson(
        _readMap(json['capabilities']),
      ),
    );
  }
}

class StationDashboardStation {
  final String id;
  final String name;

  const StationDashboardStation({
    required this.id,
    required this.name,
  });

  factory StationDashboardStation.fromJson(Map<String, dynamic> json) {
    return StationDashboardStation(
      id: _readString(json['id']),
      name: _readString(json['name']),
    );
  }
}

class StationDashboardSummary {
  final int departuresTotal;
  final int departuresOpen;
  final int departuresDeparted;
  final int travelersExpected;
  final int ticketsActive;
  final int ticketsChecked;
  final int ticketsRemaining;
  final double boardingRate;
  final int departuresWithTravelers;
  final int blockedSeats;
  final int alertsTotal;
  final int confirmedReservations;

  const StationDashboardSummary({
    required this.departuresTotal,
    required this.departuresOpen,
    required this.departuresDeparted,
    required this.travelersExpected,
    required this.ticketsActive,
    required this.ticketsChecked,
    required this.ticketsRemaining,
    required this.boardingRate,
    required this.departuresWithTravelers,
    required this.blockedSeats,
    required this.alertsTotal,
    required this.confirmedReservations,
  });

  factory StationDashboardSummary.fromJson(Map<String, dynamic> json) {
    return StationDashboardSummary(
      departuresTotal: _readInt(json['departures_total']),
      departuresOpen: _readInt(json['departures_open']),
      departuresDeparted: _readInt(json['departures_departed']),
      travelersExpected: _readInt(json['travelers_expected']),
      ticketsActive: _readInt(json['tickets_active']),
      ticketsChecked: _readInt(json['tickets_checked']),
      ticketsRemaining: _readInt(json['tickets_remaining']),
      boardingRate: _readDouble(json['boarding_rate']),
      departuresWithTravelers: _readInt(json['departures_with_travelers']),
      blockedSeats: _readInt(json['blocked_seats']),
      alertsTotal: _readInt(json['alerts_total']),
      confirmedReservations: _readInt(json['confirmed_reservations']),
    );
  }
}

class StationDashboardDeparture {
  final String id;
  final DateTime? departureDate;
  final String departureTime;
  final String departureTimeDisplay;
  final String destinationName;
  final String serviceClassName;
  final StationDashboardStatus status;
  final int travelersExpected;
  final int ticketsChecked;
  final int ticketsRemaining;
  final double boardingRate;
  final int? totalCapacity;
  final int? availableCapacity;
  final int blockedSeats;
  final int alertsCount;

  const StationDashboardDeparture({
    required this.id,
    required this.departureDate,
    required this.departureTime,
    required this.departureTimeDisplay,
    required this.destinationName,
    required this.serviceClassName,
    required this.status,
    required this.travelersExpected,
    required this.ticketsChecked,
    required this.ticketsRemaining,
    required this.boardingRate,
    required this.totalCapacity,
    required this.availableCapacity,
    required this.blockedSeats,
    required this.alertsCount,
  });

  factory StationDashboardDeparture.fromJson(Map<String, dynamic> json) {
    return StationDashboardDeparture(
      id: _readString(json['id']),
      departureDate: _readDate(json['departure_date']),
      departureTime: _readString(json['departure_time']),
      departureTimeDisplay: _readString(json['departure_time_display']),
      destinationName: _readString(json['destination_name']),
      serviceClassName: _readString(json['service_class_name']),
      status: StationDashboardStatus.fromJson(_readMap(json['status'])),
      travelersExpected: _readInt(json['travelers_expected']),
      ticketsChecked: _readInt(json['tickets_checked']),
      ticketsRemaining: _readInt(json['tickets_remaining']),
      boardingRate: _readDouble(json['boarding_rate']),
      totalCapacity: _readNullableInt(json['total_capacity']),
      availableCapacity: _readNullableInt(json['available_capacity']),
      blockedSeats: _readInt(json['blocked_seats']),
      alertsCount: _readInt(json['alerts_count']),
    );
  }
}

class StationDashboardStatus {
  final String code;
  final String label;

  const StationDashboardStatus({
    required this.code,
    required this.label,
  });

  factory StationDashboardStatus.fromJson(Map<String, dynamic> json) {
    return StationDashboardStatus(
      code: _readString(json['code']),
      label: _readString(json['label']),
    );
  }
}

class StationDashboardAlert {
  final String code;
  final String severity;
  final String title;
  final String message;
  final String departureId;
  final String actionTarget;

  const StationDashboardAlert({
    required this.code,
    required this.severity,
    required this.title,
    required this.message,
    required this.departureId,
    required this.actionTarget,
  });

  factory StationDashboardAlert.fromJson(Map<String, dynamic> json) {
    return StationDashboardAlert(
      code: _readString(json['code']),
      severity: _readString(json['severity']),
      title: _readString(json['title']),
      message: _readString(json['message']),
      departureId: _readString(json['departure_id']),
      actionTarget: _readString(json['action_target']),
    );
  }
}

class StationDashboardPendingRequests {
  final int reports;
  final int cancellations;

  const StationDashboardPendingRequests({
    required this.reports,
    required this.cancellations,
  });

  factory StationDashboardPendingRequests.fromJson(Map<String, dynamic> json) {
    return StationDashboardPendingRequests(
      reports: _readInt(json['reports']),
      cancellations: _readInt(json['cancellations']),
    );
  }
}

class StationDashboardCapabilities {
  final bool canReadDepartures;
  final bool canManageDepartures;
  final bool canReadReservations;
  final bool canOpenBoarding;
  final bool canManageReports;

  const StationDashboardCapabilities({
    required this.canReadDepartures,
    required this.canManageDepartures,
    required this.canReadReservations,
    required this.canOpenBoarding,
    required this.canManageReports,
  });

  factory StationDashboardCapabilities.fromJson(Map<String, dynamic> json) {
    return StationDashboardCapabilities(
      canReadDepartures: _readBool(json['can_read_departures']),
      canManageDepartures: _readBool(json['can_manage_departures']),
      canReadReservations: _readBool(json['can_read_reservations']),
      canOpenBoarding: _readBool(json['can_open_boarding']),
      canManageReports: _readBool(json['can_manage_reports']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_readMap).toList();
}

String _readString(dynamic value) => value?.toString() ?? '';

int _readInt(dynamic value) => _readNullableInt(value) ?? 0;

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime? _readDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

DateTime? _readDateTime(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
