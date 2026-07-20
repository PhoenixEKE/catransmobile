import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';

class AdminTransportCompanyRef {
  final String id;
  final String name;
  final String? code;
  final bool isActive;

  const AdminTransportCompanyRef({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
  });

  factory AdminTransportCompanyRef.fromJson(AdminTransportJson json) {
    return AdminTransportCompanyRef(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      code: readTransportNullableString(json['code']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
    );
  }
}

class AdminTransportCityRef {
  final String id;
  final String name;
  final String country;
  final bool isActive;

  const AdminTransportCityRef({
    required this.id,
    required this.name,
    required this.country,
    required this.isActive,
  });

  factory AdminTransportCityRef.fromJson(AdminTransportJson json) {
    return AdminTransportCityRef(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      country: readTransportString(json['country']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
    );
  }
}

class AdminTransportStationRef {
  final String id;
  final String name;
  final String? code;
  final String cityName;
  final bool isActive;

  const AdminTransportStationRef({
    required this.id,
    required this.name,
    this.code,
    required this.cityName,
    required this.isActive,
  });

  factory AdminTransportStationRef.fromJson(AdminTransportJson json) {
    return AdminTransportStationRef(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      code: readTransportNullableString(json['code']),
      cityName: readTransportString(json['city_name']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
    );
  }
}
