import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';

class AdminInternalUserSummary {
  final String id;
  final String email;
  final String phoneNumber;
  final String lastname;
  final String firstname;
  final bool isActive;
  final String role;
  final String roleLabel;
  final StaffStationRef? station;
  final StaffCounterRef? counter;
  final List<String> scopes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminInternalUserSummary({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.lastname,
    required this.firstname,
    required this.isActive,
    required this.role,
    required this.roleLabel,
    this.station,
    this.counter,
    this.scopes = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory AdminInternalUserSummary.fromJson(JsonMap json) {
    final profile =
        _readMap(json['internal_profile']) ?? _readMap(json['profile']);
    final station = _readMap(json['station']) ?? _readMap(profile?['station']);
    final counter = _readMap(json['counter']) ?? _readMap(profile?['counter']);
    final role = json['role'] ?? profile?['role'];
    final roleLabel = json['role_label'] ?? profile?['role_label'];

    return AdminInternalUserSummary(
      id: _readString(json['id']),
      email: _readString(json['email']),
      phoneNumber: _readString(json['phone_number']),
      lastname: _readString(json['lastname']),
      firstname: _readString(json['firstname']),
      isActive: json['is_active'] as bool? ?? true,
      role: _readString(role),
      roleLabel: _readString(roleLabel ?? role),
      station: station == null ? null : StaffRef.fromJson(station),
      counter: counter == null ? null : StaffRef.fromJson(counter),
      scopes: _readStringList(json['scopes']),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }
}

class AdminInternalUserDetail extends AdminInternalUserSummary {
  const AdminInternalUserDetail({
    required super.id,
    required super.email,
    required super.phoneNumber,
    required super.lastname,
    required super.firstname,
    required super.isActive,
    required super.role,
    required super.roleLabel,
    super.station,
    super.counter,
    super.scopes,
    super.createdAt,
    super.updatedAt,
  });

  factory AdminInternalUserDetail.fromJson(JsonMap json) {
    final summary = AdminInternalUserSummary.fromJson(json);
    return AdminInternalUserDetail(
      id: summary.id,
      email: summary.email,
      phoneNumber: summary.phoneNumber,
      lastname: summary.lastname,
      firstname: summary.firstname,
      isActive: summary.isActive,
      role: summary.role,
      roleLabel: summary.roleLabel,
      station: summary.station,
      counter: summary.counter,
      scopes: summary.scopes,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
    );
  }
}

class AdminInternalRoleOption {
  final String value;
  final String label;
  final List<String> scopes;

  const AdminInternalRoleOption({
    required this.value,
    required this.label,
    this.scopes = const [],
  });

  factory AdminInternalRoleOption.fromJson(JsonMap json) {
    return AdminInternalRoleOption(
      value: _readString(json['value'] ?? json['role'] ?? json['code']),
      label: _readString(json['label'] ?? json['name']),
      scopes: _readStringList(json['scopes']),
    );
  }
}

class AdminInternalUserCreateRequest {
  final String email;
  final String phoneNumber;
  final String lastname;
  final String firstname;
  final String role;
  final String? stationId;
  final String? counterId;

  const AdminInternalUserCreateRequest({
    required this.email,
    required this.phoneNumber,
    required this.lastname,
    required this.firstname,
    required this.role,
    this.stationId,
    this.counterId,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone_number': phoneNumber,
        'lastname': lastname,
        'firstname': firstname,
        'role': role,
        if (stationId != null) 'station_id': stationId,
        if (counterId != null) 'counter_id': counterId,
      };
}

class AdminInternalUserUpdateRequest {
  final String? email;
  final String? phoneNumber;
  final String? lastname;
  final String? firstname;
  final String? role;
  final String? stationId;
  final String? counterId;
  final bool clearStation;
  final bool clearCounter;

  const AdminInternalUserUpdateRequest({
    this.email,
    this.phoneNumber,
    this.lastname,
    this.firstname,
    this.role,
    this.stationId,
    this.counterId,
    this.clearStation = false,
    this.clearCounter = false,
  });

  Map<String, dynamic> toJson() => {
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (lastname != null) 'lastname': lastname,
        if (firstname != null) 'firstname': firstname,
        if (role != null) 'role': role,
        if (clearStation)
          'station_id': null
        else if (stationId != null)
          'station_id': stationId,
        if (clearCounter)
          'counter_id': null
        else if (counterId != null)
          'counter_id': counterId,
      };
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _readString(dynamic value) => value?.toString() ?? '';

List<String> _readStringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

DateTime? _readDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
