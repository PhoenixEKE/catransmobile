import 'package:catrans_app/models/staff/admin/transport/admin_transport_common.dart';

class AdminCompany {
  final String id;
  final String name;
  final String? code;
  final String? customerServicePhone;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const AdminCompany({
    required this.id,
    required this.name,
    this.code,
    this.customerServicePhone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminCompany.fromJson(AdminTransportJson json) {
    return AdminCompany(
      id: readTransportString(json['id']),
      name: readTransportString(json['name']),
      code: readTransportNullableString(json['code']),
      customerServicePhone:
          readTransportNullableString(json['customer_service_phone']),
      isActive: readTransportBool(json['is_active'], defaultValue: true),
      createdAt: readTransportString(json['created_at']),
      updatedAt: readTransportString(json['updated_at']),
    );
  }
}

class AdminCompanyCreateRequest {
  final String name;
  final String? code;
  final String? customerServicePhone;

  const AdminCompanyCreateRequest({
    required this.name,
    this.code,
    this.customerServicePhone,
  });

  AdminTransportJson toJson() => {
        'name': name.trim(),
        if (trimmedOrNull(code) != null) 'code': trimmedOrNull(code),
        if (trimmedOrNull(customerServicePhone) != null)
          'customer_service_phone': trimmedOrNull(customerServicePhone),
      };
}

class AdminCompanyUpdateRequest {
  final String? name;
  final AdminTransportPatchField<String> code;
  final AdminTransportPatchField<String> customerServicePhone;

  const AdminCompanyUpdateRequest({
    this.name,
    this.code = const AdminTransportPatchField.absent(),
    this.customerServicePhone = const AdminTransportPatchField.absent(),
  });

  AdminTransportJson toJson() {
    final json = <String, dynamic>{
      if (trimmedOrNull(name) != null) 'name': trimmedOrNull(name),
    };
    writePatchField(json, 'code', code, encode: trimmedOrNull);
    writePatchField(
      json,
      'customer_service_phone',
      customerServicePhone,
      encode: trimmedOrNull,
    );
    return json;
  }
}
