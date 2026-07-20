import 'package:catrans_app/models/staff/paged_result.dart';

class AdminDashboardMetric {
  final String id;
  final String label;
  final String value;
  final String? currency;
  final Map<String, dynamic> raw;

  const AdminDashboardMetric({
    required this.id,
    required this.label,
    required this.value,
    this.currency,
    this.raw = const {},
  });

  factory AdminDashboardMetric.fromJson(JsonMap json) {
    return AdminDashboardMetric(
      id: (json['id'] ?? json['code'] ?? json['key'] ?? '').toString(),
      label: (json['label'] ?? json['name'] ?? '').toString(),
      value:
          (json['value'] ?? json['amount'] ?? json['count'] ?? '').toString(),
      currency: json['currency']?.toString(),
      raw: json,
    );
  }
}

class AdminDashboardResponse {
  final Map<String, dynamic> raw;

  const AdminDashboardResponse({required this.raw});

  factory AdminDashboardResponse.fromJson(JsonMap json) {
    return AdminDashboardResponse(raw: json);
  }
}
