class CatalogBookingPolicy {
  final bool salesOpen;
  final String reason;
  final String message;
  final DateTime? departureAt;
  final DateTime? salesCutoffAt;
  final DateTime? physicalTicketPickupDeadlineAt;
  final int? salesCutoffMinutes;
  final int? physicalTicketPickupMinutes;

  const CatalogBookingPolicy({
    required this.salesOpen,
    required this.reason,
    required this.message,
    this.departureAt,
    this.salesCutoffAt,
    this.physicalTicketPickupDeadlineAt,
    this.salesCutoffMinutes,
    this.physicalTicketPickupMinutes,
  });

  factory CatalogBookingPolicy.fromJson(Map<String, dynamic> json) {
    return CatalogBookingPolicy(
      salesOpen: json['sales_open'] == true,
      reason: json['reason'] as String? ?? '',
      message: json['message'] as String? ?? '',
      departureAt: _tryParseDateTime(json['departure_at']),
      salesCutoffAt: _tryParseDateTime(json['sales_cutoff_at']),
      physicalTicketPickupDeadlineAt: _tryParseDateTime(
        json['physical_ticket_pickup_deadline_at'],
      ),
      salesCutoffMinutes: json['sales_cutoff_minutes'] as int?,
      physicalTicketPickupMinutes:
          json['physical_ticket_pickup_minutes'] as int?,
    );
  }

  static DateTime? _tryParseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Map<String, dynamic> toJson() => {
        'sales_open': salesOpen,
        'reason': reason,
        'message': message,
        'departure_at': departureAt?.toIso8601String(),
        'sales_cutoff_at': salesCutoffAt?.toIso8601String(),
        'physical_ticket_pickup_deadline_at':
            physicalTicketPickupDeadlineAt?.toIso8601String(),
        'sales_cutoff_minutes': salesCutoffMinutes,
        'physical_ticket_pickup_minutes': physicalTicketPickupMinutes,
      };
}
