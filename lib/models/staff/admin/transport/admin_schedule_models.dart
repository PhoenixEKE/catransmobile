import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';

class AdminSchedule {
  final String id;
  final AdminTransportStationRef station;
  final AdminTransportRouteRef? route;
  final AdminTransportServiceClassRef? serviceClass;
  final String departureTime;
  final String departureTimeRaw;
  final String? routeNote;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminSchedule({
    required this.id,
    required this.station,
    this.route,
    this.serviceClass,
    required this.departureTime,
    required this.departureTimeRaw,
    this.routeNote,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTime {
    final raw = departureTimeRaw.trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    final time = departureTime.trim();
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time.isEmpty ? '-' : time;
  }

  String get displayRoute => route?.displayLabel ?? '-';

  String get displayServiceClass => serviceClass?.name.trim().isNotEmpty == true
      ? serviceClass!.name
      : '-';

  String get displaySummary => '$displayRoute · $displayServiceClass · $displayTime';

  factory AdminSchedule.fromJson(AdminTransportJson json) {
    final route = json['route'];
    final serviceClass = json['service_class'];
    return AdminSchedule(
      id: readTransportString(json['id']),
      station:
          AdminTransportStationRef.fromJson(readTransportMap(json['station'])),
      route: route is Map
          ? AdminTransportRouteRef.fromJson(readTransportMap(route))
          : null,
      serviceClass: serviceClass is Map
          ? AdminTransportServiceClassRef.fromJson(
              readTransportMap(serviceClass))
          : null,
      departureTime: readTransportString(json['departure_time']),
      departureTimeRaw: readTransportString(json['departure_time_raw']),
      routeNote: readTransportNullableString(json['route_note']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminScheduleCreateRequest {
  final String stationId;
  final String routeId;
  final String serviceClassId;
  final String departureTime;
  final String? routeNote;

  const AdminScheduleCreateRequest({
    required this.stationId,
    required this.routeId,
    required this.serviceClassId,
    required this.departureTime,
    this.routeNote,
  });

  AdminTransportJson toJson() => {
        'station_id': stationId.trim(),
        'route_id': routeId.trim(),
        'service_class_id': serviceClassId.trim(),
        'departure_time': normalizeScheduleTime(departureTime),
        if (trimmedOrNull(routeNote) != null)
          'route_note': trimmedOrNull(routeNote),
      };
}

class AdminScheduleUpdateRequest {
  final String? stationId;
  final String? routeId;
  final String? serviceClassId;
  final String? departureTime;
  final AdminTransportPatchField<String> routeNote;

  const AdminScheduleUpdateRequest({
    this.stationId,
    this.routeId,
    this.serviceClassId,
    this.departureTime,
    this.routeNote = const AdminTransportPatchField.absent(),
  });

  AdminTransportJson toJson() {
    final json = <String, dynamic>{
      if (trimmedOrNull(stationId) != null)
        'station_id': trimmedOrNull(stationId),
      if (trimmedOrNull(routeId) != null) 'route_id': trimmedOrNull(routeId),
      if (trimmedOrNull(serviceClassId) != null)
        'service_class_id': trimmedOrNull(serviceClassId),
      if (trimmedOrNull(departureTime) != null)
        'departure_time': normalizeScheduleTime(departureTime!),
    };
    writePatchField(json, 'route_note', routeNote, encode: trimmedOrNull);
    return json;
  }
}

String normalizeScheduleTime(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 5) {
    return trimmed.substring(0, 5);
  }
  return trimmed;
}
