import 'package:catrans_app/models/operations/departure.dart';
import 'package:catrans_app/models/operations/seat_layout_seat.dart';
import 'package:catrans_app/models/accounts/user.dart';

enum SeatStatus { available, held, reserved, blocked, legacy_unknown }

class DepartureSeat {
  final String id;
  final Departure departure;
  final SeatLayoutSeat? layoutSeat;
  final int seatNumber;
  final SeatStatus status;
  final DateTime? reservedAt;
  final DateTime? blockedAt;
  final User? blockedBy;
  final String? blockedReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepartureSeat({
    required this.id,
    required this.departure,
    this.layoutSeat,
    required this.seatNumber,
    this.status = SeatStatus.available,
    this.reservedAt,
    this.blockedAt,
    this.blockedBy,
    this.blockedReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => status == SeatStatus.available;
  bool get isHeld => status == SeatStatus.held;
  bool get isReserved => status == SeatStatus.reserved;
  bool get isBlocked => status == SeatStatus.blocked;

  Map<String, dynamic> toJson() => {
    'id': id,
    'departure': departure.toJson(),
    'layout_seat': layoutSeat?.toJson(),
    'seat_number': seatNumber,
    'status': status.name,
    'reserved_at': reservedAt?.toIso8601String(),
    'blocked_at': blockedAt?.toIso8601String(),
    'blocked_by': blockedBy?.toJson(),
    'blocked_reason': blockedReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory DepartureSeat.fromJson(Map<String, dynamic> json) => DepartureSeat(
    id: json['id'],
    departure: Departure.fromJson(json['departure']),
    layoutSeat: json['layout_seat'] != null ? SeatLayoutSeat.fromJson(json['layout_seat']) : null,
    seatNumber: json['seat_number'],
    status: SeatStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SeatStatus.available,
    ),
    reservedAt: json['reserved_at'] != null ? DateTime.parse(json['reserved_at']) : null,
    blockedAt: json['blocked_at'] != null ? DateTime.parse(json['blocked_at']) : null,
    blockedBy: json['blocked_by'] != null ? User.fromJson(json['blocked_by']) : null,
    blockedReason: json['blocked_reason'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}