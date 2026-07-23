typedef LoyaltyJson = Map<String, dynamic>;

class LoyaltyServiceClassRef {
  final String id;
  final String code;
  final String name;

  const LoyaltyServiceClassRef({
    required this.id,
    required this.code,
    required this.name,
  });

  factory LoyaltyServiceClassRef.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyServiceClassRef(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}

class LoyaltyRule {
  final String id;
  final LoyaltyServiceClassRef? serviceClass;
  final int pointsPerTicket;
  final bool isActive;

  const LoyaltyRule({
    required this.id,
    this.serviceClass,
    required this.pointsPerTicket,
    required this.isActive,
  });

  factory LoyaltyRule.fromJson(LoyaltyJson json) {
    return LoyaltyRule(
      id: json['id']?.toString() ?? '',
      serviceClass: json['service_class'] != null
          ? LoyaltyServiceClassRef.fromJson(json['service_class'])
          : null,
      pointsPerTicket: _readInt(json['points_per_ticket']) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
