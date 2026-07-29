class CatalogSeatSummary {
  final int total;
  final int available;
  final int held;
  final int reserved;
  final int blocked;

  const CatalogSeatSummary({
    required this.total,
    required this.available,
    required this.held,
    required this.reserved,
    required this.blocked,
  });

  factory CatalogSeatSummary.fromJson(Map<String, dynamic> json) {
    return CatalogSeatSummary(
      total: json['total'] as int,
      available: json['available'] as int,
      held: json['held'] as int,
      reserved: json['reserved'] as int,
      blocked: json['blocked'] as int,
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
}
