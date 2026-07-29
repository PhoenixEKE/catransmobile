class ServiceClass {
  final String id;
  final String code;
  final String name;
  final int defaultLoyaltyPoints;
  final int rewardThresholdPoints;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceClass({
    required this.id,
    required this.code,
    required this.name,
    this.defaultLoyaltyPoints = 5,
    this.rewardThresholdPoints = 100,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'default_loyalty_points': defaultLoyaltyPoints,
    'reward_threshold_points': rewardThresholdPoints,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ServiceClass.fromJson(Map<String, dynamic> json) => ServiceClass(
    id: json['id'],
    code: json['code'],
    name: json['name'],
    defaultLoyaltyPoints: json['default_loyalty_points'] ?? 5,
    rewardThresholdPoints: json['reward_threshold_points'] ?? 100,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}