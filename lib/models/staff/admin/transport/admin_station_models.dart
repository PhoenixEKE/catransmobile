import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';
import 'package:catrans_app/models/staff/admin/transport/admin_transport_refs.dart';

class AdminStation {
  final String id;
  final String name;
  final String normalizedName;
  final String? code;
  final String? phoneLine;
  final String? representative;
  final String cityNameSnapshot;
  final String cityName;
  final AdminTransportCompanyRef company;
  final AdminTransportCityRef? city;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminStation({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.code,
    this.phoneLine,
    this.representative,
    required this.cityNameSnapshot,
    required this.cityName,
    required this.company,
    this.city,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminStation.fromJson(AdminTransportJson json) {
    final city = json['city'];
    return AdminStation(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      normalizedName: readTransportString(json['normalized_name']),
      code: readTransportNullableString(json['code']),
      phoneLine: readTransportNullableString(json['phone_line']),
      representative: readTransportNullableString(json['representative']),
      cityNameSnapshot: readTransportString(json['city_name_snapshot']),
      cityName: readTransportString(json['city_name']),
      company: AdminTransportCompanyRef.fromJson(
        readTransportMap(json['company']),
      ),
      city: city is Map ? AdminTransportCityRef.fromJson(readTransportMap(city)) : null,
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminStationCreateRequest {
  final String name;
  final String companyId;
  final String? cityId;
  final String? code;
  final String? phoneLine;
  final String? representative;

  const AdminStationCreateRequest({
    required this.name,
    required this.companyId,
    this.cityId,
    this.code,
    this.phoneLine,
    this.representative,
  });

  AdminTransportJson toJson() => {
        'name': name.trim(),
        'company_id': companyId,
        if (trimmedOrNull(cityId) != null) 'city_id': trimmedOrNull(cityId),
        if (trimmedOrNull(code) != null) 'code': trimmedOrNull(code),
        if (trimmedOrNull(phoneLine) != null)
          'phone_line': trimmedOrNull(phoneLine),
        if (trimmedOrNull(representative) != null)
          'representative': trimmedOrNull(representative),
      };
}

class AdminStationUpdateRequest {
  final String? name;
  final String? companyId;
  final AdminTransportPatchField<String> cityId;
  final AdminTransportPatchField<String> code;
  final AdminTransportPatchField<String> phoneLine;
  final AdminTransportPatchField<String> representative;

  const AdminStationUpdateRequest({
    this.name,
    this.companyId,
    this.cityId = const AdminTransportPatchField.absent(),
    this.code = const AdminTransportPatchField.absent(),
    this.phoneLine = const AdminTransportPatchField.absent(),
    this.representative = const AdminTransportPatchField.absent(),
  });

  AdminTransportJson toJson() {
    final json = <String, dynamic>{
      if (trimmedOrNull(name) != null) 'name': trimmedOrNull(name),
      if (trimmedOrNull(companyId) != null) 'company_id': trimmedOrNull(companyId),
    };
    writePatchField(json, 'city_id', cityId, encode: trimmedOrNull);
    writePatchField(json, 'code', code, encode: trimmedOrNull);
    writePatchField(json, 'phone_line', phoneLine, encode: trimmedOrNull);
    writePatchField(json, 'representative', representative, encode: trimmedOrNull);
    return json;
  }
}
