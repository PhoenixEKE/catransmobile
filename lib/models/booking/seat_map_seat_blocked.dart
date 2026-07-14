class SeatMapSeatBlocked {
  final DateTime? blockedAt;
  final String blockedReason;
  final String? blockedBy;

  const SeatMapSeatBlocked({
    this.blockedAt,
    required this.blockedReason,
    this.blockedBy,
  });

  factory SeatMapSeatBlocked.fromJson(Map<String, dynamic> json) {
    return SeatMapSeatBlocked(
      blockedAt: DateTime.tryParse(json['blocked_at'] as String? ?? ''),
      blockedReason: json['blocked_reason'] as String? ?? '',
      blockedBy: json['blocked_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'blocked_at': blockedAt?.toIso8601String(),
        'blocked_reason': blockedReason,
        'blocked_by': blockedBy,
      };
}
