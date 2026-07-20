import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';

class AdminStationCounter {
  final String id;
  final AdminTransportStationRef station;
  final String code;
  final String label;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminStationCounter({
    required this.id,
    required this.station,
    required this.code,
    required this.label,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminStationCounter.fromJson(AdminTransportJson json) {
    return AdminStationCounter(
      id: readTransportString(json['id']),
      station: AdminTransportStationRef.fromJson(
        readTransportMap(json['station']),
      ),
      code: readTransportString(json['code']),
      label: readTransportString(json['label']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminStationCounterCreateRequest {
  final String code;
  final String label;

  const AdminStationCounterCreateRequest({
    required this.code,
    required this.label,
  });

  AdminTransportJson toJson() => {
        'code': code.trim(),
        'label': label.trim(),
      };
}

class AdminStationCounterUpdateRequest {
  final String? code;
  final String? label;

  const AdminStationCounterUpdateRequest({
    this.code,
    this.label,
  });

  AdminTransportJson toJson() => {
        if (trimmedOrNull(code) != null) 'code': trimmedOrNull(code),
        if (trimmedOrNull(label) != null) 'label': trimmedOrNull(label),
      };
}
