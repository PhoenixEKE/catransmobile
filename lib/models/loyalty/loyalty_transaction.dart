import 'package:catrans_app/models/loyalty/loyalty_account.dart';
import 'package:catrans_app/models/booking/reservation_item.dart';
import 'package:catrans_app/models/ticketing/ticket.dart';
import 'package:catrans_app/models/transport/service_class.dart';

enum TransactionType { earned, spent, reversed, restored, adjustment }

class LoyaltyTransaction {
  final String id;
  final LoyaltyAccount account;
  final Reservation? reservation;
  final Ticket? ticket;
  final ServiceClass? serviceClass;
  final TransactionType transactionType;
  final int points;
  final int balanceAfter;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.account,
    this.reservation,
    this.ticket,
    this.serviceClass,
    required this.transactionType,
    required this.points,
    required this.balanceAfter,
    this.metadata,
    required this.createdAt,
  });

  bool get isEarn => transactionType == TransactionType.earned;
  bool get isSpent => transactionType == TransactionType.spent;

  Map<String, dynamic> toJson() => {
    'id': id,
    'account': account.toJson(),
    'reservation': reservation?.toJson(),
    'ticket': ticket?.toJson(),
    'service_class': serviceClass?.toJson(),
    'transaction_type': transactionType.name,
    'points': points,
    'balance_after': balanceAfter,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
  };

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) => LoyaltyTransaction(
    id: json['id'],
    account: LoyaltyAccount.fromJson(json['account']),
    reservation: json['reservation'] != null ? Reservation.fromJson(json['reservation']) : null,
    ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    transactionType: TransactionType.values.firstWhere(
      (e) => e.name == json['transaction_type'],
      orElse: () => TransactionType.adjustment,
    ),
    points: json['points'],
    balanceAfter: json['balance_after'],
    metadata: json['metadata'],
    createdAt: DateTime.parse(json['created_at']),
  );
}