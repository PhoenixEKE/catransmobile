import 'package:catrans_app/models/transport/route.dart';
import 'package:catrans_app/models/transport/service_class.dart';

class RouteFare {
  final String id;
  final Route route;
  final ServiceClass serviceClass;
  final double amount;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteFare({
    required this.id,
    required this.route,
    required this.serviceClass,
    required this.amount,
    this.currency = 'XOF',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'route': route.toJson(),
    'service_class': serviceClass.toJson(),
    'amount': amount,
    'currency': currency,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory RouteFare.fromJson(Map<String, dynamic> json) => RouteFare(
    id: json['id'],
    route: Route.fromJson(json['route']),
    serviceClass: ServiceClass.fromJson(json['service_class']),
    amount: json['amount'],
    currency: json['currency'] ?? 'XOF',
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}