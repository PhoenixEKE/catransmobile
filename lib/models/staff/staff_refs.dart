class StaffRef {
  final String id;
  final String? code;
  final String name;
  final bool? isActive;

  const StaffRef({
    required this.id,
    this.code,
    required this.name,
    this.isActive,
  });

  String get label {
    final normalizedCode = code?.trim();
    if (normalizedCode != null && normalizedCode.isNotEmpty) {
      return '$normalizedCode - $name';
    }
    return name;
  }

  factory StaffRef.fromJson(Map<String, dynamic> json) {
    return StaffRef(
      id: _readString(json['id']),
      code: _readNullableString(json['code']),
      name: _readString(
        json['name'] ?? json['label'] ?? json['display_name'] ?? json['title'],
      ),
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (code != null) 'code': code,
        'name': name,
        if (isActive != null) 'is_active': isActive,
      };

  static String _readString(dynamic value) => value?.toString() ?? '';
  static String? _readNullableString(dynamic value) => value?.toString();
}

typedef StaffStationRef = StaffRef;
typedef StaffCounterRef = StaffRef;
typedef StaffCompanyRef = StaffRef;
typedef StaffCityRef = StaffRef;
typedef StaffServiceClassRef = StaffRef;
typedef StaffRouteRef = StaffRef;
typedef StaffSeatLayoutRef = StaffRef;
