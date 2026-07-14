class SeatHoldResponse {
  final String id;
  final String departureSeatId;
  final int seatNumber;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const SeatHoldResponse({
    required this.id,
    required this.departureSeatId,
    required this.seatNumber,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory SeatHoldResponse.fromJson(Map<String, dynamic> json) {
    return SeatHoldResponse(
      id: json['id'] as String? ?? '',
      departureSeatId: json['departure_seat_id'] as String? ?? '',
      seatNumber: _readInt(json['seat_number']),
      status: json['status'] as String? ?? '',
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isActive => status == 'active';

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeLeft {
    final duration = expiresAt.difference(DateTime.now());
    return duration.isNegative ? Duration.zero : duration;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departure_seat_id': departureSeatId,
        'seat_number': seatNumber,
        'status': status,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
