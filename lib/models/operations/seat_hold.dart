import 'package:catrans_app/models/operations/departure_seat.dart';
import 'package:catrans_app/models/accounts/customer_profile.dart';

enum HoldStatus { active, confirmed, expired, cancelled }

class SeatHold {
  final String id;
  final DepartureSeat departureSeat;
  final CustomerProfile? customer;
  final HoldStatus status;
  final DateTime expiresAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SeatHold({
    required this.id,
    required this.departureSeat,
    this.customer,
    this.status = HoldStatus.active,
    required this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == HoldStatus.active;
  bool get isConfirmed => status == HoldStatus.confirmed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'departure_seat': departureSeat.toJson(),
    'customer': customer?.toJson(),
    'status': status.name,
    'expires_at': expiresAt.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SeatHold.fromJson(Map<String, dynamic> json) => SeatHold(
    id: json['id'],
    departureSeat: DepartureSeat.fromJson(json['departure_seat']),
    customer: json['customer'] != null ? CustomerProfile.fromJson(json['customer']) : null,
    status: HoldStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => HoldStatus.active,
    ),
    expiresAt: DateTime.parse(json['expires_at']),
    confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
    cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}