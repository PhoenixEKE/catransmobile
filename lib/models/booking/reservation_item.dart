import 'package:catrans_app/models/accounts/customer_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';

enum ReservationChannel { customer_app, station_counter, admin_portal, legacy }
enum ReservationStatus { pending_payment, confirmed, cancelled, expired, failed }

class Reservation {
  final String id;
  final String reference;
  final CustomerProfile? customer;
  final User? createdBy;
  final ReservationChannel channel;
  final ReservationStatus status;
  final String? customerPhoneSnapshot;
  final String? customerLastnameSnapshot;
  final String? customerFirstnameSnapshot;
  final double totalAmount;
  final String currency;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reservation({
    required this.id,
    required this.reference,
    this.customer,
    this.createdBy,
    this.channel = ReservationChannel.customer_app,
    this.status = ReservationStatus.pending_payment,
    this.customerPhoneSnapshot,
    this.customerLastnameSnapshot,
    this.customerFirstnameSnapshot,
    required this.totalAmount,
    this.currency = 'XOF',
    this.expiresAt,
    this.confirmedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get customerName => customerFirstnameSnapshot != null
      ? '$customerFirstnameSnapshot $customerLastnameSnapshot'
      : 'Client inconnu';

  bool get isPending => status == ReservationStatus.pending_payment;
  bool get isConfirmed => status == ReservationStatus.confirmed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'customer': customer?.toJson(),
    'created_by': createdBy?.toJson(),
    'channel': channel.name,
    'status': status.name,
    'customer_phone_snapshot': customerPhoneSnapshot,
    'customer_lastname_snapshot': customerLastnameSnapshot,
    'customer_firstname_snapshot': customerFirstnameSnapshot,
    'total_amount': totalAmount,
    'currency': currency,
    'expires_at': expiresAt?.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'],
    reference: json['reference'],
    customer: json['customer'] != null ? CustomerProfile.fromJson(json['customer']) : null,
    createdBy: json['created_by'] != null ? User.fromJson(json['created_by']) : null,
    channel: ReservationChannel.values.firstWhere(
      (e) => e.name == json['channel'],
      orElse: () => ReservationChannel.customer_app,
    ),
    status: ReservationStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ReservationStatus.pending_payment,
    ),
    customerPhoneSnapshot: json['customer_phone_snapshot'],
    customerLastnameSnapshot: json['customer_lastname_snapshot'],
    customerFirstnameSnapshot: json['customer_firstname_snapshot'],
    totalAmount: json['total_amount'],
    currency: json['currency'] ?? 'XOF',
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
    cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}