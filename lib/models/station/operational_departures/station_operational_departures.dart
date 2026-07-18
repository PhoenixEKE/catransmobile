class StationOperationalDeparturesResponse {
  final DateTime? date;
  final DateTime? generatedAt;
  final StationOperationalStation station;
  final StationOperationalSummary summary;
  final StationOperationalCapabilities capabilities;
  final int count;
  final String? next;
  final String? previous;
  final List<StationOperationalDeparture> results;

  const StationOperationalDeparturesResponse({
    required this.date,
    required this.generatedAt,
    required this.station,
    required this.summary,
    required this.capabilities,
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory StationOperationalDeparturesResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationOperationalDeparturesResponse(
      date: _readDate(json['date']),
      generatedAt: _readDateTime(json['generated_at']),
      station: StationOperationalStation.fromJson(_readMap(json['station'])),
      summary: StationOperationalSummary.fromJson(_readMap(json['summary'])),
      capabilities: StationOperationalCapabilities.fromJson(
        _readMap(json['capabilities']),
      ),
      count: _readInt(json['count']),
      next: _readNullableString(json['next']),
      previous: _readNullableString(json['previous']),
      results: _readList(json['results'])
          .map(StationOperationalDeparture.fromJson)
          .toList(),
    );
  }
}

class StationOperationalStation {
  final String id;
  final String name;

  const StationOperationalStation({required this.id, required this.name});

  factory StationOperationalStation.fromJson(Map<String, dynamic> json) {
    return StationOperationalStation(
      id: _readString(json['id']),
      name: _readString(json['name']),
    );
  }
}

class StationOperationalSummary {
  final int departuresTotal;
  final int departuresScheduled;
  final int departuresOpen;
  final int departuresClosed;
  final int departuresDeparted;
  final int departuresCancelled;
  final int travelersExpected;
  final int ticketsActive;
  final int ticketsChecked;
  final int ticketsRemaining;
  final double boardingRate;
  final int blockedSeats;
  final int alertsTotal;

  const StationOperationalSummary({
    required this.departuresTotal,
    required this.departuresScheduled,
    required this.departuresOpen,
    required this.departuresClosed,
    required this.departuresDeparted,
    required this.departuresCancelled,
    required this.travelersExpected,
    required this.ticketsActive,
    required this.ticketsChecked,
    required this.ticketsRemaining,
    required this.boardingRate,
    required this.blockedSeats,
    required this.alertsTotal,
  });

  factory StationOperationalSummary.fromJson(Map<String, dynamic> json) {
    return StationOperationalSummary(
      departuresTotal: _readInt(json['departures_total']),
      departuresScheduled: _readInt(json['departures_scheduled']),
      departuresOpen: _readInt(json['departures_open']),
      departuresClosed: _readInt(json['departures_closed']),
      departuresDeparted: _readInt(json['departures_departed']),
      departuresCancelled: _readInt(json['departures_cancelled']),
      travelersExpected: _readInt(json['travelers_expected']),
      ticketsActive: _readInt(json['tickets_active']),
      ticketsChecked: _readInt(json['tickets_checked']),
      ticketsRemaining: _readInt(json['tickets_remaining']),
      boardingRate: _readDouble(json['boarding_rate']),
      blockedSeats: _readInt(json['blocked_seats']),
      alertsTotal: _readInt(json['alerts_total']),
    );
  }
}

class StationOperationalCapabilities {
  final bool canReadDepartures;
  final bool canManageDepartures;
  final bool canOpenBoarding;
  final bool canReadManifest;
  final bool canReadBoardingSummary;

  const StationOperationalCapabilities({
    required this.canReadDepartures,
    required this.canManageDepartures,
    required this.canOpenBoarding,
    required this.canReadManifest,
    required this.canReadBoardingSummary,
  });

  factory StationOperationalCapabilities.fromJson(Map<String, dynamic> json) {
    return StationOperationalCapabilities(
      canReadDepartures: _readBool(json['can_read_departures']),
      canManageDepartures: _readBool(json['can_manage_departures']),
      canOpenBoarding: _readBool(json['can_open_boarding']),
      canReadManifest: _readBool(json['can_read_manifest']),
      canReadBoardingSummary: _readBool(json['can_read_boarding_summary']),
    );
  }
}

class StationOperationalDeparture {
  final String id;
  final DateTime? departureDate;
  final String? departureTime;
  final String? departureTimeRaw;
  final String? departureTimeDisplay;
  final String stationName;
  final String destinationName;
  final String? routeName;
  final String? serviceClassId;
  final String? serviceClassName;
  final String status;
  final String statusLabel;
  final int travelersExpected;
  final int ticketsActive;
  final int ticketsChecked;
  final int ticketsRemaining;
  final double boardingRate;
  final int validationRejections;
  final int? totalCapacity;
  final int? availableCapacity;
  final int blockedSeats;
  final String capacityMode;
  final int alertsCount;
  final List<StationOperationalDepartureAlert> alerts;
  final DateTime? openedAt;
  final String? openedByName;
  final DateTime? closedAt;
  final String? closedByName;
  final DateTime? departedAt;
  final String? departedByName;
  final StationOperationalDepartureActions availableActions;
  final String? nextAction;

  const StationOperationalDeparture({
    required this.id,
    required this.departureDate,
    required this.departureTime,
    required this.departureTimeRaw,
    required this.departureTimeDisplay,
    required this.stationName,
    required this.destinationName,
    required this.routeName,
    required this.serviceClassId,
    required this.serviceClassName,
    required this.status,
    required this.statusLabel,
    required this.travelersExpected,
    required this.ticketsActive,
    required this.ticketsChecked,
    required this.ticketsRemaining,
    required this.boardingRate,
    required this.validationRejections,
    required this.totalCapacity,
    required this.availableCapacity,
    required this.blockedSeats,
    required this.capacityMode,
    required this.alertsCount,
    required this.alerts,
    required this.openedAt,
    required this.openedByName,
    required this.closedAt,
    required this.closedByName,
    required this.departedAt,
    required this.departedByName,
    required this.availableActions,
    required this.nextAction,
  });

  factory StationOperationalDeparture.fromJson(Map<String, dynamic> json) {
    return StationOperationalDeparture(
      id: _readString(json['id']),
      departureDate: _readDate(json['departure_date']),
      departureTime: _readNullableString(json['departure_time']),
      departureTimeRaw: _readNullableString(json['departure_time_raw']),
      departureTimeDisplay: _readNullableString(json['departure_time_display']),
      stationName: _readString(json['station_name']),
      destinationName: _readString(json['destination_name']),
      routeName: _readNullableString(json['route_name']),
      serviceClassId: _readNullableString(json['service_class_id']),
      serviceClassName: _readNullableString(json['service_class_name']),
      status: _readString(json['status']),
      statusLabel: _readString(json['status_label']),
      travelersExpected: _readInt(json['travelers_expected']),
      ticketsActive: _readInt(json['tickets_active']),
      ticketsChecked: _readInt(json['tickets_checked']),
      ticketsRemaining: _readInt(json['tickets_remaining']),
      boardingRate: _readDouble(json['boarding_rate']),
      validationRejections: _readInt(json['validation_rejections']),
      totalCapacity: _readNullableInt(json['total_capacity']),
      availableCapacity: _readNullableInt(json['available_capacity']),
      blockedSeats: _readInt(json['blocked_seats']),
      capacityMode: _readString(json['capacity_mode']),
      alertsCount: _readInt(json['alerts_count']),
      alerts: _readList(json['alerts'])
          .map(StationOperationalDepartureAlert.fromJson)
          .toList(),
      openedAt: _readDateTime(json['opened_at']),
      openedByName: _readNullableString(json['opened_by_name']),
      closedAt: _readDateTime(json['closed_at']),
      closedByName: _readNullableString(json['closed_by_name']),
      departedAt: _readDateTime(json['departed_at']),
      departedByName: _readNullableString(json['departed_by_name']),
      availableActions: StationOperationalDepartureActions.fromJson(
        _readMap(json['available_actions']),
      ),
      nextAction: _readNullableString(json['next_action']),
    );
  }

  String get displayTime {
    final value = departureTimeDisplay ?? departureTimeRaw ?? departureTime;
    return value == null || value.trim().isEmpty ? '-' : value;
  }

  String get displayServiceClass => serviceClassName ?? 'Classe non renseignée';

  String get displayRoute => routeName ?? destinationName;

  double get progressValue {
    final value = boardingRate / 100;
    if (value.isNaN || value.isInfinite) return 0;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  String get capacityLabel {
    if (availableCapacity == null || totalCapacity == null) {
      return 'Capacité non disponible';
    }
    return '$availableCapacity places disponibles sur $totalCapacity';
  }

  String get capacityModeLabel {
    switch (capacityMode) {
      case 'assigned_seats':
        return 'Placement par siège';
      case 'unassigned_capacity':
        return 'Placement en gare';
      case 'unavailable':
        return 'Capacité indisponible';
    }
    return 'Capacité indisponible';
  }

  List<StationOperationalDepartureAlert> get priorityAlerts {
    return alerts.take(2).toList();
  }
}

class StationOperationalDepartureAlert {
  final String code;
  final String severity;
  final String title;
  final String message;
  final String? departureId;
  final String actionTarget;

  const StationOperationalDepartureAlert({
    required this.code,
    required this.severity,
    required this.title,
    required this.message,
    required this.departureId,
    required this.actionTarget,
  });

  factory StationOperationalDepartureAlert.fromJson(Map<String, dynamic> json) {
    return StationOperationalDepartureAlert(
      code: _readString(json['code']),
      severity: _readString(json['severity']),
      title: _readString(json['title']),
      message: _readString(json['message']),
      departureId: _readNullableString(json['departure_id']),
      actionTarget: _readString(json['action_target']),
    );
  }
}

class StationOperationalDepartureActions {
  final bool canOpen;
  final bool canClose;
  final bool canMarkDeparted;
  final bool canOpenBoarding;
  final bool canViewManifest;
  final bool canViewSummary;

  const StationOperationalDepartureActions({
    required this.canOpen,
    required this.canClose,
    required this.canMarkDeparted,
    required this.canOpenBoarding,
    required this.canViewManifest,
    required this.canViewSummary,
  });

  factory StationOperationalDepartureActions.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationOperationalDepartureActions(
      canOpen: _readBool(json['can_open']),
      canClose: _readBool(json['can_close']),
      canMarkDeparted: _readBool(json['can_mark_departed']),
      canOpenBoarding: _readBool(json['can_open_boarding']),
      canViewManifest: _readBool(json['can_view_manifest']),
      canViewSummary: _readBool(json['can_view_summary']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_readMap).toList();
}

String _readString(dynamic value) => value?.toString() ?? '';

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

double _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? _readDate(dynamic value) {
  final text = _readNullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

DateTime? _readDateTime(dynamic value) {
  final text = _readNullableString(value);
  if (text == null) return null;
  return DateTime.tryParse(text)?.toLocal();
}
