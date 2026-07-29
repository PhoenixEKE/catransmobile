import 'package:catrans_app/models/staff/paged_result.dart';

class AdminSeatClassZoneServiceClassRef {
  final String id;
  final String code;
  final String name;
  final bool isActive;

  const AdminSeatClassZoneServiceClassRef({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
  });

  factory AdminSeatClassZoneServiceClassRef.fromJson(dynamic json) {
    final map = json is Map ? JsonMap.from(json) : const <String, dynamic>{};
    return AdminSeatClassZoneServiceClassRef(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class AdminSeatClassZone {
  final String id;
  final AdminSeatClassZoneServiceClassRef serviceClass;
  final int seatNumberStart;
  final int seatNumberEnd;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const AdminSeatClassZone({
    required this.id,
    required this.serviceClass,
    required this.seatNumberStart,
    required this.seatNumberEnd,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminSeatClassZone.fromJson(JsonMap json) {
    return AdminSeatClassZone(
      id: json['id']?.toString() ?? '',
      serviceClass:
          AdminSeatClassZoneServiceClassRef.fromJson(json['service_class']),
      seatNumberStart: _readInt(json['seat_number_start']) ?? 0,
      seatNumberEnd: _readInt(json['seat_number_end']) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get displayRange => seatNumberStart == seatNumberEnd
      ? 'Siège $seatNumberStart'
      : 'Sièges $seatNumberStart à $seatNumberEnd';
}

/// One row submitted to the `replace/` endpoint. The endpoint always
/// replaces the *entire* active zone set for the template in one call
/// (there is no incremental add/remove on the backend), so the caller
/// must always send the complete desired state, not a diff.
class AdminSeatClassZoneDraft {
  final String serviceClassId;
  final int seatNumberStart;
  final int seatNumberEnd;

  const AdminSeatClassZoneDraft({
    required this.serviceClassId,
    required this.seatNumberStart,
    required this.seatNumberEnd,
  });

  JsonMap toJson() => {
        'service_class_id': serviceClassId,
        'seat_number_start': seatNumberStart,
        'seat_number_end': seatNumberEnd,
      };
}

class AdminSeatClassZoneReplaceRequest {
  final List<AdminSeatClassZoneDraft> zones;

  const AdminSeatClassZoneReplaceRequest({required this.zones});

  JsonMap toJson() => {
        'zones': zones.map((zone) => zone.toJson()).toList(),
      };
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
