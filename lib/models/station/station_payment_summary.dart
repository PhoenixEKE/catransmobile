class StationPaymentSummary {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final String method;
  final String methodLabel;
  final String provider;
  final String providerLabel;
  final String amount;
  final String currency;
  final String? payerPhone;
  final String? payerName;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const StationPaymentSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.method,
    required this.methodLabel,
    required this.provider,
    required this.providerLabel,
    required this.amount,
    required this.currency,
    this.payerPhone,
    this.payerName,
    this.paidAt,
    this.createdAt,
  });

  String get displayAmount => '$amount $currency'.trim();

  factory StationPaymentSummary.fromJson(Map<String, dynamic> json) {
    return StationPaymentSummary(
      id: _readString(json['id']),
      reference: _readString(json['reference']),
      status: _readString(json['status']),
      statusLabel: _readString(json['status_label']),
      method: _readString(json['method']),
      methodLabel: _readString(json['method_label']),
      provider: _readString(json['provider']),
      providerLabel: _readString(json['provider_label']),
      amount: _readString(json['amount']),
      currency: _readString(json['currency']),
      payerPhone: _readNullableString(json['payer_phone_snapshot']),
      payerName: _readNullableString(json['payer_name_snapshot']),
      paidAt: _parseDateTime(json['paid_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

String _readString(dynamic value) => value?.toString() ?? '';
String? _readNullableString(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
