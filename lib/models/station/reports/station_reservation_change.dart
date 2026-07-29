import 'package:catrans_app/models/station/reports/station_report_common.dart';

class StationReservationChange {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final String changeType;
  final String changeTypeLabel;
  final DateTime? requestedAt;
  final String reservationId;
  final String reservationReference;
  final String? customerName;
  final String customerPhone;
  final int itemsCount;
  final StationReportDepartureSummary? currentDepartureSummary;
  final StationReportDepartureSummary? requestedDepartureSummary;
  final String? reason;
  final String? rejectionReason;
  final String? requestedByName;
  final String? reviewedByName;
  final String? appliedByName;
  final DateTime? reviewedAt;
  final DateTime? appliedAt;
  final DateTime? cancelledAt;
  final StationReportAvailableActions availableActions;
  final StationReportEligibility eligibility;

  const StationReservationChange({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.changeType,
    required this.changeTypeLabel,
    this.requestedAt,
    required this.reservationId,
    required this.reservationReference,
    this.customerName,
    required this.customerPhone,
    required this.itemsCount,
    this.currentDepartureSummary,
    this.requestedDepartureSummary,
    this.reason,
    this.rejectionReason,
    this.requestedByName,
    this.reviewedByName,
    this.appliedByName,
    this.reviewedAt,
    this.appliedAt,
    this.cancelledAt,
    required this.availableActions,
    required this.eligibility,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isApplied => status == 'applied';
  bool get isRejected => status == 'rejected';

  factory StationReservationChange.fromJson(Map<String, dynamic> json) {
    return StationReservationChange(
      id: readReportString(json['id']),
      reference: readReportString(json['reference']),
      status: readReportString(json['status']),
      statusLabel: readReportString(json['status_label']),
      changeType: readReportString(json['change_type']),
      changeTypeLabel: readReportString(json['change_type_label']),
      requestedAt: readReportDateTime(json['requested_at']),
      reservationId: readReportString(json['reservation_id']),
      reservationReference: readReportString(json['reservation_reference']),
      customerName: readReportNullableString(json['customer_name']),
      customerPhone: readReportString(json['customer_phone']),
      itemsCount: readReportInt(json['items_count']),
      currentDepartureSummary: json['current_departure_summary'] == null
          ? null
          : StationReportDepartureSummary.fromJson(
              readReportObject(json['current_departure_summary']),
            ),
      requestedDepartureSummary: json['requested_departure_summary'] == null
          ? null
          : StationReportDepartureSummary.fromJson(
              readReportObject(json['requested_departure_summary']),
            ),
      reason: readReportNullableString(json['reason']),
      rejectionReason: readReportNullableString(json['rejection_reason']),
      requestedByName: readReportNullableString(json['requested_by_name']),
      reviewedByName: readReportNullableString(json['reviewed_by_name']),
      appliedByName: readReportNullableString(json['applied_by_name']),
      reviewedAt: readReportDateTime(json['reviewed_at']),
      appliedAt: readReportDateTime(json['applied_at']),
      cancelledAt: readReportDateTime(json['cancelled_at']),
      availableActions: StationReportAvailableActions.fromJson(
        readReportObject(json['available_actions']),
      ),
      eligibility: StationReportEligibility.fromJson(
        readReportObject(json['eligibility']),
      ),
    );
  }
}
