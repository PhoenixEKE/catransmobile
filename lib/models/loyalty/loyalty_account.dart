import 'package:catrans_app/models/accounts/customer_profile.dart';

class LoyaltyAccount {
  final String id;
  final CustomerProfile customer;
  final int balancePoints;
  final int totalEarnedPoints;
  final int totalSpentPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyAccount({
    required this.id,
    required this.customer,
    this.balancePoints = 0,
    this.totalEarnedPoints = 0,
    this.totalSpentPoints = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get ratioPrestige => 0.0; // À calculer avec les transactions

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer': customer.toJson(),
    'balance_points': balancePoints,
    'total_earned_points': totalEarnedPoints,
    'total_spent_points': totalSpentPoints,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
    id: json['id'],
    customer: CustomerProfile.fromJson(json['customer']),
    balancePoints: json['balance_points'] ?? 0,
    totalEarnedPoints: json['total_earned_points'] ?? 0,
    totalSpentPoints: json['total_spent_points'] ?? 0,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}