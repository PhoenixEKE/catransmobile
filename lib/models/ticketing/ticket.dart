import 'package:catrans_app/models/booking/reservation_item.dart';
import 'package:catrans_app/models/accounts/customer_profile.dart';
import 'package:catrans_app/models/operations/departure.dart';
import 'package:catrans_app/models/operations/departure_seat.dart';
import 'package:catrans_app/models/transport/route.dart';
import 'package:catrans_app/models/transport/service_class.dart';

enum TicketStatus { issued, used, cancelled, expired, invalidated, legacy }
enum TicketChannel { customer_app, station_counter, admin_portal, legacy }

class Ticket {
  final String id;
  final String reference;
  final Reservation reservation;
  final String reservationItemId; 
  final CustomerProfile? customer;
  final Departure departure;
  final DepartureSeat? departureSeat;
  final Route? route;
  final ServiceClass? serviceClass;
  final int? seatNumberSnapshot;
  final Map<String, String> travelerSnapshot;
  final double amount;
  final String currency;
  final String validationToken;
  final TicketStatus status;
  final TicketChannel channel;
  final DateTime? issuedAt;
  final DateTime? usedAt;
  final DateTime? cancelledAt;
  final DateTime? expiredAt;
  final DateTime? invalidatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.reference,
    required this.reservation,
    required this.reservationItemId,
    this.customer,
    required this.departure,
    this.departureSeat,
    this.route,
    this.serviceClass,
    this.seatNumberSnapshot,
    this.travelerSnapshot = const {},
    required this.amount,
    this.currency = 'XOF',
    required this.validationToken,
    this.status = TicketStatus.issued,
    this.channel = TicketChannel.customer_app,
    this.issuedAt,
    this.usedAt,
    this.cancelledAt,
    this.expiredAt,
    this.invalidatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isValid => status == TicketStatus.issued;
  bool get isUsed => status == TicketStatus.used;

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'reservation': reservation.toJson(),
    'reservation_item_id': reservationItemId,
    'customer': customer?.toJson(),
    'departure': departure.toJson(),
    'departure_seat': departureSeat?.toJson(),
    'route': route?.toJson(),
    'service_class': serviceClass?.toJson(),
    'seat_number_snapshot': seatNumberSnapshot,
    'traveler_snapshot': travelerSnapshot,
    'amount': amount,
    'currency': currency,
    'validation_token': validationToken,
    'status': status.name,
    'channel': channel.name,
    'issued_at': issuedAt?.toIso8601String(),
    'used_at': usedAt?.toIso8601String(),
    'cancelled_at': cancelledAt?.toIso8601String(),
    'expired_at': expiredAt?.toIso8601String(),
    'invalidated_at': invalidatedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'],
    reference: json['reference'],
    reservation: Reservation.fromJson(json['reservation']),
    reservationItemId: json['reservation_item_id'] ?? '',
    customer: json['customer'] != null ? CustomerProfile.fromJson(json['customer']) : null,
    departure: Departure.fromJson(json['departure']),
    departureSeat: json['departure_seat'] != null ? DepartureSeat.fromJson(json['departure_seat']) : null,
    route: json['route'] != null ? Route.fromJson(json['route']) : null,
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    seatNumberSnapshot: json['seat_number_snapshot'],
    travelerSnapshot: Map<String, String>.from(json['traveler_snapshot'] ?? {}),
    amount: json['amount'],
    currency: json['currency'] ?? 'XOF',
    validationToken: json['validation_token'],
    status: TicketStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TicketStatus.issued,
    ),
    channel: TicketChannel.values.firstWhere(
      (e) => e.name == json['channel'],
      orElse: () => TicketChannel.customer_app,
    ),
    issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at']) : null,
    usedAt: json['used_at'] != null ? DateTime.parse(json['used_at']) : null,
    cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
    expiredAt: json['expired_at'] != null ? DateTime.parse(json['expired_at']) : null,
    invalidatedAt: json['invalidated_at'] != null ? DateTime.parse(json['invalidated_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}