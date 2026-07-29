import 'package:catrans_app/models/staff/paged_result.dart';

class AdminDepartureStatus {
  final String code;
  final String label;

  const AdminDepartureStatus({required this.code, required this.label});

  factory AdminDepartureStatus.fromJson(dynamic json) {
    if (json is Map) {
      final map = JsonMap.from(json);
      return AdminDepartureStatus(
        code: map['code']?.toString() ?? '',
        label: map['label']?.toString() ?? map['code']?.toString() ?? '',
      );
    }
    final value = json?.toString() ?? '';
    return AdminDepartureStatus(code: value, label: value);
  }
}

class AdminDepartureRef {
  final String id;
  final String name;
  final String? code;
  final String? label;

  const AdminDepartureRef({
    required this.id,
    required this.name,
    this.code,
    this.label,
  });

  factory AdminDepartureRef.fromJson(dynamic json) {
    if (json is Map) {
      final map = JsonMap.from(json);
      final name =
          (map['name'] ?? map['label'] ?? map['reference'] ?? '').toString();
      return AdminDepartureRef(
        id: map['id']?.toString() ?? '',
        name: name,
        code: map['code']?.toString(),
        label: map['label']?.toString(),
      );
    }
    return AdminDepartureRef(id: '', name: json?.toString() ?? '');
  }
}

class AdminDeparture {
  final String id;
  final String? departureTemplateId;
  final AdminDepartureRef? station;
  final AdminDepartureRef? route;
  final AdminDepartureRef? serviceClass;
  final AdminDepartureRef? seatLayout;
  final String departureDate;
  final String? departureTime;
  final AdminDepartureStatus status;
  final String? openedAt;
  final String? closedAt;
  final String? departedAt;
  final String? createdAt;
  final String? updatedAt;
  final JsonMap raw;

  const AdminDeparture({
    required this.id,
    this.departureTemplateId,
    this.station,
    this.route,
    this.serviceClass,
    this.seatLayout,
    required this.departureDate,
    this.departureTime,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.departedAt,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory AdminDeparture.fromJson(JsonMap json) {
    return AdminDeparture(
      id: json['id']?.toString() ?? '',
      departureTemplateId: json['departure_template_id']?.toString(),
      station: _readRef(json['station']),
      route: _readRef(json['route']),
      serviceClass: _readRef(json['service_class']),
      seatLayout: _readRef(json['seat_layout']),
      departureDate: json['departure_date']?.toString() ?? '',
      departureTime: json['departure_time']?.toString(),
      status: AdminDepartureStatus.fromJson(json['status']),
      openedAt: json['opened_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      departedAt: json['departed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      raw: json,
    );
  }

  String get displayRoute {
    final routeName = route?.label ?? route?.name;
    if (routeName != null && routeName.isNotEmpty) return routeName;
    return station?.name ?? 'Route non renseignée';
  }

  String get displayStation => station?.name ?? 'Gare non renseignée';
  String get displayClass =>
      serviceClass?.name ?? serviceClass?.code ?? 'Classe non renseignée';
  String get displaySchedule => departureTime == null || departureTime!.isEmpty
      ? departureDate
      : '$departureDate à $departureTime';

  bool get canGenerateSeats => status.code == 'scheduled';
  bool get canOpen => status.code == 'scheduled' || status.code == 'closed';
  bool get canClose => status.code == 'open';
  bool get canDepart => status.code == 'closed';
  bool get canCancel => status.code != 'departed' && status.code != 'cancelled';
  bool get canReschedule => status.code == 'scheduled' || status.code == 'closed';
}

class AdminDepartureCreateRequest {
  final String departureTemplateId;
  final String departureDate;

  const AdminDepartureCreateRequest({
    required this.departureTemplateId,
    required this.departureDate,
  });

  JsonMap toJson() => {
        'departure_template_id': departureTemplateId,
        'departure_date': departureDate,
      };
}

class AdminDepartureDateUpdateRequest {
  final String departureDate;
  final String? departureTime;

  const AdminDepartureDateUpdateRequest({
    required this.departureDate,
    this.departureTime,
  });

  JsonMap toJson() => {
        'departure_date': departureDate,
        if (departureTime != null && departureTime!.isNotEmpty)
          'departure_time': departureTime,
      };
}

class AdminDepartureCreateResult {
  final bool created;
  final AdminDeparture departure;

  const AdminDepartureCreateResult({
    required this.created,
    required this.departure,
  });

  factory AdminDepartureCreateResult.fromJson(JsonMap json) {
    final rawDeparture = json['departure'];
    return AdminDepartureCreateResult(
      created: json['created'] as bool? ?? false,
      departure: rawDeparture is Map
          ? AdminDeparture.fromJson(JsonMap.from(rawDeparture))
          : AdminDeparture.fromJson(const {}),
    );
  }
}

class AdminDepartureDatesRequest {
  final List<String> departureDates;

  const AdminDepartureDatesRequest({required this.departureDates});

  JsonMap toJson() => {'departure_dates': departureDates};
}

class AdminDepartureGenerationResultItem {
  final String departureDate;
  final bool created;
  final AdminDeparture? departure;

  const AdminDepartureGenerationResultItem({
    required this.departureDate,
    required this.created,
    this.departure,
  });

  factory AdminDepartureGenerationResultItem.fromJson(JsonMap json) {
    final rawDeparture = json['departure'];
    return AdminDepartureGenerationResultItem(
      departureDate: json['departure_date']?.toString() ?? '',
      created: json['created'] as bool? ?? false,
      departure: rawDeparture is Map
          ? AdminDeparture.fromJson(JsonMap.from(rawDeparture))
          : null,
    );
  }
}

class AdminDepartureGenerationResult {
  final int createdCount;
  final int existingCount;
  final List<AdminDepartureGenerationResultItem> departures;

  const AdminDepartureGenerationResult({
    required this.createdCount,
    required this.existingCount,
    required this.departures,
  });

  factory AdminDepartureGenerationResult.fromJson(JsonMap json) {
    final rawDepartures = json['departures'];
    return AdminDepartureGenerationResult(
      createdCount: _readInt(json['created_count']) ?? 0,
      existingCount: _readInt(json['existing_count']) ?? 0,
      departures: rawDepartures is List
          ? rawDepartures
              .whereType<Map>()
              .map((item) => AdminDepartureGenerationResultItem.fromJson(
                    JsonMap.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class AdminDepartureSeatVisual {
  final int rowNumber;
  final int columnNumber;
  final int? positionX;
  final int? positionY;
  final bool isSelectable;
  final bool isWindow;
  final bool isAisle;

  const AdminDepartureSeatVisual({
    required this.rowNumber,
    required this.columnNumber,
    this.positionX,
    this.positionY,
    required this.isSelectable,
    required this.isWindow,
    required this.isAisle,
  });

  factory AdminDepartureSeatVisual.fromJson(dynamic json) {
    final map = json is Map ? JsonMap.from(json) : const <String, dynamic>{};
    return AdminDepartureSeatVisual(
      rowNumber: _readInt(map['row_number']) ?? 1,
      columnNumber: _readInt(map['column_number']) ?? 1,
      positionX: _readInt(map['position_x']),
      positionY: _readInt(map['position_y']),
      isSelectable: map['is_selectable'] as bool? ?? true,
      isWindow: map['is_window'] as bool? ?? false,
      isAisle: map['is_aisle'] as bool? ?? false,
    );
  }
}

class AdminDepartureSeatBlocked {
  final String? blockedAt;
  final String blockedReason;
  final String? blockedBy;

  const AdminDepartureSeatBlocked({
    this.blockedAt,
    required this.blockedReason,
    this.blockedBy,
  });

  factory AdminDepartureSeatBlocked.fromJson(dynamic json) {
    final map = json is Map ? JsonMap.from(json) : const <String, dynamic>{};
    return AdminDepartureSeatBlocked(
      blockedAt: map['blocked_at']?.toString(),
      blockedReason: map['blocked_reason']?.toString() ?? '',
      blockedBy: map['blocked_by']?.toString(),
    );
  }
}

class AdminDepartureSeat {
  final String id;
  final int seatNumber;
  final String status;
  final String seatType;
  final String displayLabel;
  final AdminDepartureSeatVisual visual;
  final AdminDepartureSeatBlocked blocked;
  final bool activeHoldPresent;
  final JsonMap raw;

  const AdminDepartureSeat({
    required this.id,
    required this.seatNumber,
    required this.status,
    required this.seatType,
    required this.displayLabel,
    required this.visual,
    required this.blocked,
    required this.activeHoldPresent,
    this.raw = const {},
  });

  factory AdminDepartureSeat.fromJson(JsonMap json) {
    return AdminDepartureSeat(
      id: json['id']?.toString() ?? '',
      seatNumber: _readInt(json['seat_number']) ?? 0,
      status: json['status']?.toString() ?? 'legacy_unknown',
      seatType: json['seat_type']?.toString() ?? 'standard',
      displayLabel: json['display_label']?.toString() ??
          json['seat_number']?.toString() ??
          '',
      visual: AdminDepartureSeatVisual.fromJson(json['visual']),
      blocked: AdminDepartureSeatBlocked.fromJson(json['blocked']),
      activeHoldPresent: json['active_hold_present'] as bool? ?? false,
      raw: json,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isHeld => status == 'held' || activeHoldPresent;
  bool get isReserved => status == 'reserved';
  bool get isBlocked => status == 'blocked';
  bool get canBlock => isAvailable;
  bool get canUnblock => isBlocked;
}

class AdminDepartureSeatsResponse {
  final String departureId;
  final int count;
  final List<AdminDepartureSeat> results;

  const AdminDepartureSeatsResponse({
    required this.departureId,
    required this.count,
    required this.results,
  });

  factory AdminDepartureSeatsResponse.fromJson(JsonMap json) {
    final rawResults = json['results'];
    final seats = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map((item) => AdminDepartureSeat.fromJson(JsonMap.from(item)))
            .toList()
        : <AdminDepartureSeat>[];
    return AdminDepartureSeatsResponse(
      departureId: json['departure_id']?.toString() ?? '',
      count: _readInt(json['count']) ?? seats.length,
      results: seats,
    );
  }

  int get available => results.where((seat) => seat.isAvailable).length;
  int get held => results.where((seat) => seat.isHeld).length;
  int get reserved => results.where((seat) => seat.isReserved).length;
  int get blocked => results.where((seat) => seat.isBlocked).length;
}

class AdminDepartureSeatActionRequest {
  final List<int> seatNumbers;
  final String reason;

  const AdminDepartureSeatActionRequest({
    required this.seatNumbers,
    required this.reason,
  });

  JsonMap toJson() => {
        'seat_numbers': seatNumbers,
        'reason': reason,
      };
}

class AdminDepartureSeatGenerationResult {
  final AdminDeparture? departure;
  final int expectedCount;
  final int existingCount;
  final int createdCount;
  final bool alreadyGenerated;
  final List<AdminDepartureSeat> seats;

  const AdminDepartureSeatGenerationResult({
    this.departure,
    required this.expectedCount,
    required this.existingCount,
    required this.createdCount,
    required this.alreadyGenerated,
    required this.seats,
  });

  factory AdminDepartureSeatGenerationResult.fromJson(JsonMap json) {
    final rawDeparture = json['departure'];
    final rawSeats = json['seats'];
    return AdminDepartureSeatGenerationResult(
      departure: rawDeparture is Map
          ? AdminDeparture.fromJson(JsonMap.from(rawDeparture))
          : null,
      expectedCount: _readInt(json['expected_count']) ?? 0,
      existingCount: _readInt(json['existing_count']) ?? 0,
      createdCount: _readInt(json['created_count']) ?? 0,
      alreadyGenerated: json['already_generated'] as bool? ?? false,
      seats: rawSeats is List
          ? rawSeats
              .whereType<Map>()
              .map((item) => AdminDepartureSeat.fromJson(JsonMap.from(item)))
              .toList()
          : const [],
    );
  }
}

class AdminDepartureSeatMap {
  final JsonMap departure;
  final JsonMap layout;
  final bool seatsGenerated;
  final JsonMap counts;
  final List<JsonMap> zones;
  final List<JsonMap> seats;

  const AdminDepartureSeatMap({
    required this.departure,
    required this.layout,
    required this.seatsGenerated,
    required this.counts,
    required this.zones,
    required this.seats,
  });

  factory AdminDepartureSeatMap.fromJson(JsonMap json) {
    final rawZones = json['zones'];
    final rawSeats = json['seats'];
    return AdminDepartureSeatMap(
      departure: _readJsonMap(json['departure']),
      layout: _readJsonMap(json['layout']),
      seatsGenerated: json['seats_generated'] as bool? ?? false,
      counts: _readJsonMap(json['counts']),
      zones: rawZones is List
          ? rawZones.whereType<Map>().map((item) => JsonMap.from(item)).toList()
          : const [],
      seats: rawSeats is List
          ? rawSeats.whereType<Map>().map((item) => JsonMap.from(item)).toList()
          : const [],
    );
  }

  int get total => _readInt(counts['total']) ?? seats.length;
  int get available => _readInt(counts['available']) ?? 0;
  int get held => _readInt(counts['held']) ?? 0;
  int get reserved => _readInt(counts['reserved']) ?? 0;
  int get blocked => _readInt(counts['blocked']) ?? 0;
}

class AdminDepartureActionResponse {
  final String message;
  final AdminDeparture? departure;

  const AdminDepartureActionResponse({required this.message, this.departure});

  factory AdminDepartureActionResponse.fromJson(JsonMap json) {
    final departureJson = json['departure'];
    return AdminDepartureActionResponse(
      message: json['message']?.toString() ??
          json['detail']?.toString() ??
          'Action effectuée.',
      departure: departureJson is Map
          ? AdminDeparture.fromJson(JsonMap.from(departureJson))
          : null,
    );
  }
}

class AdminDepartureSeatActionResponse {
  final String departureId;
  final String action;
  final int changedCount;
  final int unchangedCount;
  final List<JsonMap> results;

  const AdminDepartureSeatActionResponse({
    required this.departureId,
    required this.action,
    required this.changedCount,
    required this.unchangedCount,
    required this.results,
  });

  factory AdminDepartureSeatActionResponse.fromJson(JsonMap json) {
    final rawResults = json['results'];
    return AdminDepartureSeatActionResponse(
      departureId: json['departure_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      changedCount: _readInt(json['changed_count']) ?? 0,
      unchangedCount: _readInt(json['unchanged_count']) ?? 0,
      results: rawResults is List
          ? rawResults
              .whereType<Map>()
              .map((item) => JsonMap.from(item))
              .toList()
          : const [],
    );
  }
}

AdminDepartureRef? _readRef(dynamic value) {
  if (value == null) return null;
  return AdminDepartureRef.fromJson(value);
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

JsonMap _readJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return JsonMap.from(value);
  return const {};
}
