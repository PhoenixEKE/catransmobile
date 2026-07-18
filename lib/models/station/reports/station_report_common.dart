Map<String, dynamic> readReportObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<dynamic> readReportList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String readReportString(dynamic value) => value?.toString() ?? '';

String? readReportNullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

int readReportInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool readReportBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? readReportDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

class StationReportAvailableActions {
  final bool canApprove;
  final bool canReject;
  final bool canApply;
  final bool canViewReservation;

  const StationReportAvailableActions({
    required this.canApprove,
    required this.canReject,
    required this.canApply,
    required this.canViewReservation,
  });

  const StationReportAvailableActions.empty()
      : canApprove = false,
        canReject = false,
        canApply = false,
        canViewReservation = false;

  bool get hasAnyAction =>
      canApprove || canReject || canApply || canViewReservation;

  factory StationReportAvailableActions.fromJson(Map<String, dynamic> json) {
    return StationReportAvailableActions(
      canApprove: readReportBool(json['can_approve']),
      canReject: readReportBool(json['can_reject']),
      canApply: readReportBool(json['can_apply']),
      canViewReservation: readReportBool(json['can_view_reservation']),
    );
  }
}

class StationReportEligibility {
  final bool isEligible;
  final String? blockingCode;
  final String? blockingMessage;

  const StationReportEligibility({
    required this.isEligible,
    this.blockingCode,
    this.blockingMessage,
  });

  const StationReportEligibility.unknown()
      : isEligible = false,
        blockingCode = null,
        blockingMessage = null;

  factory StationReportEligibility.fromJson(Map<String, dynamic> json) {
    return StationReportEligibility(
      isEligible: readReportBool(json['is_eligible']),
      blockingCode: readReportNullableString(json['blocking_code']),
      blockingMessage: readReportNullableString(json['blocking_message']),
    );
  }
}

class StationReportActor {
  final String? id;
  final String? phoneNumber;
  final String? email;
  final String? lastname;
  final String? firstname;
  final String? fullName;
  final String? userType;

  const StationReportActor({
    this.id,
    this.phoneNumber,
    this.email,
    this.lastname,
    this.firstname,
    this.fullName,
    this.userType,
  });

  factory StationReportActor.fromJson(Map<String, dynamic> json) {
    return StationReportActor(
      id: readReportNullableString(json['id']),
      phoneNumber: readReportNullableString(json['phone_number']),
      email: readReportNullableString(json['email']),
      lastname: readReportNullableString(json['lastname']),
      firstname: readReportNullableString(json['firstname']),
      fullName: readReportNullableString(json['full_name']),
      userType: readReportNullableString(json['user_type']),
    );
  }
}

class StationReportDepartureSummary {
  final String id;
  final String? stationId;
  final String? stationName;
  final String? destinationName;
  final String? departureDate;
  final String? departureTime;
  final String status;
  final String statusLabel;
  final String? serviceClassCode;
  final String? serviceClassName;

  const StationReportDepartureSummary({
    required this.id,
    this.stationId,
    this.stationName,
    this.destinationName,
    this.departureDate,
    this.departureTime,
    required this.status,
    required this.statusLabel,
    this.serviceClassCode,
    this.serviceClassName,
  });

  String get routeLabel {
    final parts = [stationName, destinationName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' -> ');
    return parts.isEmpty ? '-' : parts;
  }

  factory StationReportDepartureSummary.fromJson(Map<String, dynamic> json) {
    return StationReportDepartureSummary(
      id: readReportString(json['id']),
      stationId: readReportNullableString(json['station' '_id']),
      stationName: readReportNullableString(json['station_name']),
      destinationName: readReportNullableString(json['destination_name']),
      departureDate: readReportNullableString(json['departure_date']),
      departureTime: readReportNullableString(json['departure_time']),
      status: readReportString(json['status']),
      statusLabel: readReportString(json['status_label']),
      serviceClassCode: readReportNullableString(json['service_class_code']),
      serviceClassName: readReportNullableString(json['service_class_name']),
    );
  }
}

class StationReportReservationSummary {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final String totalAmount;
  final String currency;
  final String? customerName;
  final String? customerPhone;

  const StationReportReservationSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.currency,
    this.customerName,
    this.customerPhone,
  });

  String get displayAmount => '$totalAmount $currency'.trim();

  factory StationReportReservationSummary.fromJson(Map<String, dynamic> json) {
    return StationReportReservationSummary(
      id: readReportString(json['id']),
      reference: readReportString(json['reference']),
      status: readReportString(json['status']),
      statusLabel: readReportString(json['status_label']),
      totalAmount: readReportString(json['total_amount']),
      currency: readReportString(json['currency']),
      customerName: readReportNullableString(json['customer_name']),
      customerPhone: readReportNullableString(json['customer_phone']),
    );
  }
}

class StationReportFlags {
  final bool refundAutomatic;
  final bool partialCancellationSupported;
  final bool fareAdjustmentSupported;

  const StationReportFlags({
    required this.refundAutomatic,
    required this.partialCancellationSupported,
    required this.fareAdjustmentSupported,
  });

  const StationReportFlags.empty()
      : refundAutomatic = false,
        partialCancellationSupported = false,
        fareAdjustmentSupported = false;

  factory StationReportFlags.fromJson(Map<String, dynamic> json) {
    return StationReportFlags(
      refundAutomatic: readReportBool(json['refund_automatic']),
      partialCancellationSupported:
          readReportBool(json['partial_cancellation_supported']),
      fareAdjustmentSupported:
          readReportBool(json['fare_adjustment_supported']),
    );
  }
}

class StationReportTraveler {
  final String? lastname;
  final String? firstname;
  final String? phone;

  const StationReportTraveler({this.lastname, this.firstname, this.phone});

  String get fullName => [firstname, lastname]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' ');

  factory StationReportTraveler.fromJson(Map<String, dynamic> json) {
    return StationReportTraveler(
      lastname: readReportNullableString(json['lastname']),
      firstname: readReportNullableString(json['firstname']),
      phone: readReportNullableString(json['phone']),
    );
  }
}

class StationReportTicketRef {
  final String id;
  final String reference;
  final String status;

  const StationReportTicketRef({
    required this.id,
    required this.reference,
    required this.status,
  });

  factory StationReportTicketRef.fromJson(Map<String, dynamic> json) {
    return StationReportTicketRef(
      id: readReportString(json['id']),
      reference: readReportString(json['reference']),
      status: readReportString(json['status']),
    );
  }
}
