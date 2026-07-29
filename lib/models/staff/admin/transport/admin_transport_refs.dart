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

class AdminTransportServiceClassRef {
  final String id;
  final String code;
  final String name;
  final bool allowsSeatSelection;
  final bool isActive;

  const AdminTransportServiceClassRef({
    required this.id,
    required this.code,
    required this.name,
    required this.allowsSeatSelection,
    required this.isActive,
  });

  factory AdminTransportServiceClassRef.fromJson(AdminTransportJson json) {
    return AdminTransportServiceClassRef(
      id: readTransportString(json['id']),
      code: readTransportString(json['code']),
      name: readTransportString(json['name']),
      allowsSeatSelection: readTransportBool(json['allows_seat_selection']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
    );
  }
}

class AdminTransportRouteRef {
  final String id;
  final AdminTransportStationRef departureStation;
  final AdminTransportCityRef? destinationCity;
  final String destinationName;
  final bool isActive;

  const AdminTransportRouteRef({
    required this.id,
    required this.departureStation,
    this.destinationCity,
    required this.destinationName,
    required this.isActive,
  });

  String get displayDestination {
    final cityName = destinationCity?.name.trim();
    if (cityName != null && cityName.isNotEmpty) return cityName;
    final name = destinationName.trim();
    return name.isEmpty ? '-' : name;
  }

  String get displayLabel => '${departureStation.name} -> $displayDestination';

  factory AdminTransportRouteRef.fromJson(AdminTransportJson json) {
    final destinationCity = json['destination_city'];
    return AdminTransportRouteRef(
      id: readTransportString(json['id']),
      departureStation: AdminTransportStationRef.fromJson(
          readTransportMap(json['departure_station'])),
      destinationCity: destinationCity is Map
          ? AdminTransportCityRef.fromJson(readTransportMap(destinationCity))
          : null,
      destinationName: readTransportString(json['destination_name']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
    );
  }
}
