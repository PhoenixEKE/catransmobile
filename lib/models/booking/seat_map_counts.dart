class SeatMapCounts {
  final int total;
  final int available;
  final int held;
  final int reserved;
  final int blocked;

  const SeatMapCounts({
    required this.total,
    required this.available,
    required this.held,
    required this.reserved,
    required this.blocked,
  });

  factory SeatMapCounts.fromJson(Map<String, dynamic> json) {
    return SeatMapCounts(
      total: _readInt(json['total']),
      available: _readInt(json['available']),
      held: _readInt(json['held']),
      reserved: _readInt(json['reserved']),
      blocked: _readInt(json['blocked']),
    );
  }

  bool get hasAvailableSeats => available > 0;

  Map<String, dynamic> toJson() => {
        'total': total,
        'available': available,
        'held': held,
        'reserved': reserved,
        'blocked': blocked,
      };

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
