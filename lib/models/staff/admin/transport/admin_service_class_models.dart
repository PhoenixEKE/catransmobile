import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';

class AdminServiceClass {
  final String id;
  final String code;
  final String name;
  final int defaultLoyaltyPoints;
  final int rewardThresholdPoints;
  final bool allowsSeatSelection;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminServiceClass({
    required this.id,
    required this.code,
    required this.name,
    required this.defaultLoyaltyPoints,
    required this.rewardThresholdPoints,
    required this.allowsSeatSelection,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminServiceClass.fromJson(AdminTransportJson json) {
    return AdminServiceClass(
      id: readTransportString(json['id']),
      code: readTransportString(json['code']),
      name: readTransportString(json['name']),
      defaultLoyaltyPoints: readTransportInt(json['default_loyalty_points']),
      rewardThresholdPoints: readTransportInt(json['reward_threshold_points']),
      allowsSeatSelection: readTransportBool(json['allows_seat_selection']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminServiceClassCreateRequest {
  final String code;
  final String name;
  final int? defaultLoyaltyPoints;
  final int? rewardThresholdPoints;
  final bool? allowsSeatSelection;

  const AdminServiceClassCreateRequest({
    required this.code,
    required this.name,
    this.defaultLoyaltyPoints,
    this.rewardThresholdPoints,
    this.allowsSeatSelection,
  });

  AdminTransportJson toJson() => {
        'code': code.trim(),
        'name': name.trim(),
        if (defaultLoyaltyPoints != null)
          'default_loyalty_points': defaultLoyaltyPoints,
        if (rewardThresholdPoints != null)
          'reward_threshold_points': rewardThresholdPoints,
        if (allowsSeatSelection != null)
          'allows_seat_selection': allowsSeatSelection,
      };
}

class AdminServiceClassUpdateRequest {
  final String? code;
  final String? name;
  final int? defaultLoyaltyPoints;
  final int? rewardThresholdPoints;
  final bool? allowsSeatSelection;

  const AdminServiceClassUpdateRequest({
    this.code,
    this.name,
    this.defaultLoyaltyPoints,
    this.rewardThresholdPoints,
    this.allowsSeatSelection,
  });

  AdminTransportJson toJson() => {
        if (trimmedOrNull(code) != null) 'code': trimmedOrNull(code),
        if (trimmedOrNull(name) != null) 'name': trimmedOrNull(name),
        if (defaultLoyaltyPoints != null)
          'default_loyalty_points': defaultLoyaltyPoints,
        if (rewardThresholdPoints != null)
          'reward_threshold_points': rewardThresholdPoints,
        if (allowsSeatSelection != null)
          'allows_seat_selection': allowsSeatSelection,
      };
}
