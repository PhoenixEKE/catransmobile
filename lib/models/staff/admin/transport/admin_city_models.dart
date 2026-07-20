import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';

class AdminCity {
  final String id;
  final String name;
  final String normalizedName;
  final String country;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminCity({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.country,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminCity.fromJson(AdminTransportJson json) {
    return AdminCity(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      normalizedName: readTransportString(json['normalized_name']),
      country: readTransportString(json['country']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminCityCreateRequest {
  final String name;
  final String? country;

  const AdminCityCreateRequest({
    required this.name,
    this.country,
  });

  AdminTransportJson toJson() => {
        'name': name.trim(),
        if (trimmedOrNull(country) != null) 'country': trimmedOrNull(country),
      };
}

class AdminCityUpdateRequest {
  final String? name;
  final String? country;

  const AdminCityUpdateRequest({
    this.name,
    this.country,
  });

  AdminTransportJson toJson() => {
        if (trimmedOrNull(name) != null) 'name': trimmedOrNull(name),
        if (trimmedOrNull(country) != null) 'country': trimmedOrNull(country),
      };
}
