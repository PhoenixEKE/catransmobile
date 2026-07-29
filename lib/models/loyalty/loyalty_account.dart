import 'package:catrans_app/models/loyalty/loyalty_rule.dart';

class LoyaltyAccountCustomerRef {
  final String id;
  final String userId;
  final String phoneNumber;
  final String lastname;
  final String firstname;
  final String fullName;

  const LoyaltyAccountCustomerRef({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.lastname,
    required this.firstname,
    required this.fullName,
  });

  factory LoyaltyAccountCustomerRef.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyAccountCustomerRef(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      phoneNumber: map['phone_number']?.toString() ?? '',
      lastname: map['lastname']?.toString() ?? '',
      firstname: map['firstname']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
    );
  }
}

class LoyaltyRedemptionEligibility {
  final bool canRedeem;
  final int missingTotalPoints;
  final int? missingPrestigePoints;
  final String rule;

  const LoyaltyRedemptionEligibility({
    required this.canRedeem,
    required this.missingTotalPoints,
    this.missingPrestigePoints,
    required this.rule,
  });

  factory LoyaltyRedemptionEligibility.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyRedemptionEligibility(
      canRedeem: map['can_redeem'] as bool? ?? false,
      missingTotalPoints: _readInt(map['missing_total_points']) ?? 0,
      missingPrestigePoints: _readInt(map['missing_prestige_points']),
      rule: map['rule']?.toString() ?? '',
    );
  }
}

class LoyaltyPointsBreakdown {
  final int totalBalance;
  final int trackedTotal;
  final int untrackedDelta;
  final int economiePoints;
  final int prestigePoints;
  final int unknownPoints;

  const LoyaltyPointsBreakdown({
    required this.totalBalance,
    required this.trackedTotal,
    required this.untrackedDelta,
    required this.economiePoints,
    required this.prestigePoints,
    required this.unknownPoints,
  });

  factory LoyaltyPointsBreakdown.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    final bySource =
        map['by_source'] is Map ? LoyaltyJson.from(map['by_source']) : const {};
    return LoyaltyPointsBreakdown(
      totalBalance: _readInt(map['total_balance']) ?? 0,
      trackedTotal: _readInt(map['tracked_total']) ?? 0,
      untrackedDelta: _readInt(map['untracked_delta']) ?? 0,
      economiePoints: _readInt(bySource['economie']) ?? 0,
      prestigePoints: _readInt(bySource['prestige']) ?? 0,
      unknownPoints: _readInt(bySource['unknown']) ?? 0,
    );
  }
}

class LoyaltyRedemptionStatus {
  final int pointsRequired;
  final int prestigePointsRequired;
  final LoyaltyPointsBreakdown breakdown;
  final LoyaltyRedemptionEligibility economie;
  final LoyaltyRedemptionEligibility prestige;

  const LoyaltyRedemptionStatus({
    required this.pointsRequired,
    required this.prestigePointsRequired,
    required this.breakdown,
    required this.economie,
    required this.prestige,
  });

  factory LoyaltyRedemptionStatus.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyRedemptionStatus(
      pointsRequired: _readInt(map['points_required']) ?? 100,
      prestigePointsRequired: _readInt(map['prestige_points_required']) ?? 70,
      breakdown: LoyaltyPointsBreakdown.fromJson(map['breakdown']),
      economie: LoyaltyRedemptionEligibility.fromJson(map['economie']),
      prestige: LoyaltyRedemptionEligibility.fromJson(map['prestige']),
    );
  }
}

class LoyaltyAccount {
  final String id;
  final LoyaltyAccountCustomerRef customer;
  final int pointsBalance;
  final int lifetimePoints;
  final bool isActive;
  final LoyaltyRedemptionStatus redemption;
  final List<LoyaltyRule> rules;
  final String? createdAt;
  final String? updatedAt;

  const LoyaltyAccount({
    required this.id,
    required this.customer,
    required this.pointsBalance,
    required this.lifetimePoints,
    required this.isActive,
    required this.redemption,
    required this.rules,
    this.createdAt,
    this.updatedAt,
  });

  factory LoyaltyAccount.fromJson(LoyaltyJson json) {
    final rawRules = json['rules'];
    return LoyaltyAccount(
      id: json['id']?.toString() ?? '',
      customer: LoyaltyAccountCustomerRef.fromJson(json['customer']),
      pointsBalance: _readInt(json['points_balance']) ?? 0,
      lifetimePoints: _readInt(json['lifetime_points']) ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      redemption: LoyaltyRedemptionStatus.fromJson(json['redemption']),
      rules: rawRules is List
          ? rawRules
              .whereType<Map>()
              .map((item) => LoyaltyRule.fromJson(LoyaltyJson.from(item)))
              .toList()
          : const [],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
