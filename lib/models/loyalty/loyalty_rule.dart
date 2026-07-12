import 'package:catrans_app/models/transport/service_class.dart';

class LoyaltyRule {
  final String id;
  final ServiceClass? serviceClass;
  final int pointsAwarded;
  final int pointsRequired;
  final int prestigeRequiredPoints;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyRule({
    required this.id,
    this.serviceClass,
    required this.pointsAwarded,
    required this.pointsRequired,
    this.prestigeRequiredPoints = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'service_class': serviceClass?.toJson(),
    'points_awarded': pointsAwarded,
    'points_required': pointsRequired,
    'prestige_required_points': prestigeRequiredPoints,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory LoyaltyRule.fromJson(Map<String, dynamic> json) => LoyaltyRule(
    id: json['id'],
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    pointsAwarded: json['points_awarded'],
    pointsRequired: json['points_required'],
    prestigeRequiredPoints: json['prestige_required_points'] ?? 0,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}