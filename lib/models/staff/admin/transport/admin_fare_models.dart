import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';

class AdminFare {
  final String id;
  final AdminTransportRouteRef route;
  final AdminTransportServiceClassRef serviceClass;
  final String amount;
  final String currency;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminFare({
    required this.id,
    required this.route,
    required this.serviceClass,
    required this.amount,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayAmount => '$amount $currency';

  factory AdminFare.fromJson(AdminTransportJson json) {
    return AdminFare(
      id: readTransportString(json['id']),
      route: AdminTransportRouteRef.fromJson(readTransportMap(json['route'])),
      serviceClass: AdminTransportServiceClassRef.fromJson(
          readTransportMap(json['service_class'])),
      amount: readTransportString(json['amount']),
      currency: readTransportString(json['currency']).isEmpty
          ? 'XOF'
          : readTransportString(json['currency']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminFareCreateRequest {
  final String routeId;
  final String serviceClassId;
  final String amount;
  final String currency;

  const AdminFareCreateRequest({
    required this.routeId,
    required this.serviceClassId,
    required this.amount,
    this.currency = 'XOF',
  });

  AdminTransportJson toJson() => {
        'route_id': routeId,
        'service_class_id': serviceClassId,
        'amount': amount.trim(),
        'currency':
            currency.trim().isEmpty ? 'XOF' : currency.trim().toUpperCase(),
      };
}

class AdminFarePatchRequest {
  final bool? isActive;

  const AdminFarePatchRequest({this.isActive});

  AdminTransportJson toJson() => {
        if (isActive != null) 'is_active': isActive,
      };
}

class AdminFareReplaceRequest {
  final String amount;
  final String currency;

  const AdminFareReplaceRequest({required this.amount, this.currency = 'XOF'});

  AdminTransportJson toJson() => {
        'amount': amount.trim(),
        'currency':
            currency.trim().isEmpty ? 'XOF' : currency.trim().toUpperCase(),
      };
}
