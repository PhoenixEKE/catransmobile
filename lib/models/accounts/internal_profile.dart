enum InternalRole {
  station_agent,
  station_manager,
  cashier,
  support,
  accounting,
  director,
  marketing,
  admin,
  legacy_unknown,
}

class InternalProfile {
  final String id;
  final InternalRole role;
  final String roleLabel;
  final InternalStationRef? station;
  final InternalCounterRef? counter;

  const InternalProfile({
    required this.id,
    required this.role,
    required this.roleLabel,
    this.station,
    this.counter,
  });

  bool get isAdmin =>
      role == InternalRole.admin || role == InternalRole.director;
  bool get isStationRole =>
      role == InternalRole.station_manager ||
      role == InternalRole.cashier ||
      role == InternalRole.station_agent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'role_label': roleLabel,
        'station': station?.toJson(),
        'counter': counter?.toJson(),
      };

  factory InternalProfile.fromJson(Map<String, dynamic> json) {
    final stationJson = json['station'];
    final counterJson = json['counter'];

    return InternalProfile(
      id: _readString(json['id']),
      role: InternalRole.values.firstWhere(
        (role) => role.name == _readString(json['role']),
        orElse: () => InternalRole.legacy_unknown,
      ),
      roleLabel: _readString(json['role_label'] ?? json['roleLabel']),
      station: stationJson is Map
          ? InternalStationRef.fromJson(Map<String, dynamic>.from(stationJson))
          : null,
      counter: counterJson is Map
          ? InternalCounterRef.fromJson(Map<String, dynamic>.from(counterJson))
          : null,
    );
  }

  static String _readString(dynamic value) => value?.toString() ?? '';
}

class InternalStationRef {
  final String id;
  final String name;

  const InternalStationRef({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory InternalStationRef.fromJson(Map<String, dynamic> json) {
    return InternalStationRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class InternalCounterRef {
  final String id;
  final String code;
  final String label;

  const InternalCounterRef({
    required this.id,
    required this.code,
    required this.label,
  });

  String get displayName {
    if (code.isEmpty) return label;
    if (label.isEmpty) return code;
    return '$code / $label';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'label': label,
      };

  factory InternalCounterRef.fromJson(Map<String, dynamic> json) {
    return InternalCounterRef(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
