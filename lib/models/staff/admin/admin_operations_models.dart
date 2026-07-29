import 'package:catrans_app/models/staff/paged_result.dart';

class AdminOperationRecord {
  final String id;
  final String name;
  final String? code;
  final String? status;
  final String? statusLabel;
  final bool isActive;
  final Map<String, dynamic> raw;

  const AdminOperationRecord({
    required this.id,
    required this.name,
    this.code,
    this.status,
    this.statusLabel,
    required this.isActive,
    this.raw = const {},
  });

  factory AdminOperationRecord.fromJson(JsonMap json) {
    return AdminOperationRecord(
      id: json['id']?.toString() ?? '',
      name:
          (json['name'] ?? json['label'] ?? json['reference'] ?? '').toString(),
      code: json['code']?.toString(),
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      raw: json,
    );
  }
}

class AdminOperationActionResponse {
  final String? detail;
  final AdminOperationRecord? object;
  final Map<String, dynamic> raw;

  const AdminOperationActionResponse({
    this.detail,
    this.object,
    this.raw = const {},
  });

  factory AdminOperationActionResponse.fromJson(JsonMap json) {
    final objectJson = json['object'] ??
        json['departure'] ??
        json['template'] ??
        json['seat_layout'];
    return AdminOperationActionResponse(
      detail: json['detail']?.toString() ?? json['message']?.toString(),
      object: objectJson is Map
          ? AdminOperationRecord.fromJson(Map<String, dynamic>.from(objectJson))
          : null,
      raw: json,
    );
  }
}

class AdminSeatLayoutWriteRequest {
  final String name;
  final String? description;
  final int? capacity;

  const AdminSeatLayoutWriteRequest({
    required this.name,
    this.description,
    this.capacity,
  });

  JsonMap toJson() => {
        'name': name.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        if (capacity != null) 'capacity': capacity,
      };
}

class AdminDepartureTemplateWriteRequest {
  final String scheduleId;
  final String seatLayoutId;

  const AdminDepartureTemplateWriteRequest({
    required this.scheduleId,
    required this.seatLayoutId,
  });

  JsonMap toJson() => {
        'schedule_id': scheduleId.trim(),
        'seat_layout_id': seatLayoutId.trim(),
      };
}
