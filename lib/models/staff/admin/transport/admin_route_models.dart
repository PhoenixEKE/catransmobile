import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';

class AdminRoute {
  final String id;
  final AdminTransportCompanyRef company;
  final AdminTransportStationRef departureStation;
  final AdminTransportCityRef? departureCity;
  final AdminTransportCityRef? destinationCity;
  final String destinationName;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminRoute({
    required this.id,
    required this.company,
    required this.departureStation,
    this.departureCity,
    this.destinationCity,
    required this.destinationName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayDestination {
    final cityName = destinationCity?.name.trim();
    if (cityName != null && cityName.isNotEmpty) return cityName;
    final name = destinationName.trim();
    return name.isEmpty ? '-' : name;
  }

  String get displayLabel => '${departureStation.name} -> $displayDestination';

  factory AdminRoute.fromJson(AdminTransportJson json) {
    final departureCity = json['departure_city'];
    final destinationCity = json['destination_city'];
    return AdminRoute(
      id: readTransportString(json['id']),
      company:
          AdminTransportCompanyRef.fromJson(readTransportMap(json['company'])),
      departureStation: AdminTransportStationRef.fromJson(
          readTransportMap(json['departure_station'])),
      departureCity: departureCity is Map
          ? AdminTransportCityRef.fromJson(readTransportMap(departureCity))
          : null,
      destinationCity: destinationCity is Map
          ? AdminTransportCityRef.fromJson(readTransportMap(destinationCity))
          : null,
      destinationName: readTransportString(json['destination_name']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminRouteCreateRequest {
  final String companyId;
  final String departureStationId;
  final String? departureCityId;
  final String? destinationCityId;
  final String? destinationName;

  const AdminRouteCreateRequest({
    required this.companyId,
    required this.departureStationId,
    this.departureCityId,
    this.destinationCityId,
    this.destinationName,
  });

  AdminTransportJson toJson() => {
        'company_id': companyId,
        'departure_station_id': departureStationId,
        if (trimmedOrNull(departureCityId) != null)
          'departure_city_id': trimmedOrNull(departureCityId),
        if (trimmedOrNull(destinationCityId) != null)
          'destination_city_id': trimmedOrNull(destinationCityId),
        if (trimmedOrNull(destinationCityId) == null &&
            trimmedOrNull(destinationName) != null)
          'destination_name': trimmedOrNull(destinationName),
      };
}

class AdminRouteUpdateRequest {
  final String? companyId;
  final String? departureStationId;
  final AdminTransportPatchField<String> departureCityId;
  final AdminTransportPatchField<String> destinationCityId;
  final AdminTransportPatchField<String> destinationName;

  const AdminRouteUpdateRequest({
    this.companyId,
    this.departureStationId,
    this.departureCityId = const AdminTransportPatchField.absent(),
    this.destinationCityId = const AdminTransportPatchField.absent(),
    this.destinationName = const AdminTransportPatchField.absent(),
  });

  AdminTransportJson toJson() {
    final json = <String, dynamic>{
      if (trimmedOrNull(companyId) != null)
        'company_id': trimmedOrNull(companyId),
      if (trimmedOrNull(departureStationId) != null)
        'departure_station_id': trimmedOrNull(departureStationId),
    };
    writePatchField(json, 'departure_city_id', departureCityId,
        encode: trimmedOrNull);
    writePatchField(json, 'destination_city_id', destinationCityId,
        encode: trimmedOrNull);
    writePatchField(json, 'destination_name', destinationName,
        encode: trimmedOrNull);
    if (json['destination_city_id'] != null) json.remove('destination_name');
    return json;
  }
}
