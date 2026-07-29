import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';

class AdminTransportRecord {
  final String id;
  final String? code;
  final String name;
  final String? label;
  final bool isActive;
  final String? description;
  final Map<String, dynamic> raw;

  const AdminTransportRecord({
    required this.id,
    this.code,
    required this.name,
    this.label,
    required this.isActive,
    this.description,
    this.raw = const {},
  });

  factory AdminTransportRecord.fromJson(JsonMap json) {
    return AdminTransportRecord(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString(),
      name: (json['name'] ?? json['label'] ?? json['title'] ?? '').toString(),
      label: json['label']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      description: json['description']?.toString(),
      raw: json,
    );
  }

  StaffRef toRef() => StaffRef(
        id: id,
        code: code,
        name: name.isNotEmpty ? name : (label ?? ''),
        isActive: isActive,
      );
}

class AdminTransportWriteRequest {
  final Map<String, dynamic> data;

  const AdminTransportWriteRequest(this.data);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
