import 'package:catrans_app/models/station/reports/station_report_common.dart';

class StationCancellation {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final String channel;
  final String channelLabel;
  final DateTime? requestedAt;
  final String reservationId;
  final String reservationReference;
  final String? customerName;
  final String customerPhone;
  final int travelersCount;
  final int ticketsCount;
  final String totalAmount;
  final String currency;
  final String? reason;
  final String? rejectionReason;
  final String? requestedByName;
  final String? reviewedByName;
  final String? appliedByName;
  final DateTime? reviewedAt;
  final DateTime? appliedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? cancelledAt;
  final StationReportAvailableActions availableActions;
  final StationReportEligibility eligibility;

  const StationCancellation({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.channel,
    required this.channelLabel,
    this.requestedAt,
    required this.reservationId,
    required this.reservationReference,
    this.customerName,
    required this.customerPhone,
    required this.travelersCount,
    required this.ticketsCount,
    required this.totalAmount,
    required this.currency,
    this.reason,
    this.rejectionReason,
    this.requestedByName,
    this.reviewedByName,
    this.appliedByName,
    this.reviewedAt,
    this.appliedAt,
    this.approvedAt,
    this.rejectedAt,
    this.cancelledAt,
    required this.availableActions,
    required this.eligibility,
  });

  String get displayAmount => '$totalAmount $currency'.trim();
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isApplied => status == 'applied';
  bool get isRejected => status == 'rejected';

  factory StationCancellation.fromJson(Map<String, dynamic> json) {
    return StationCancellation(
      id: readReportString(json['id']),
      reference: readReportString(json['reference']),
      status: readReportString(json['status']),
      statusLabel: readReportString(json['status_label']),
      channel: readReportString(json['channel']),
      channelLabel: readReportString(json['channel_label']),
      requestedAt: readReportDateTime(json['requested_at']),
      reservationId: readReportString(json['reservation_id']),
      reservationReference: readReportString(json['reservation_reference']),
      customerName: readReportNullableString(json['customer_name']),
      customerPhone: readReportString(json['customer_phone']),
      travelersCount: readReportInt(json['travelers_count']),
      ticketsCount: readReportInt(json['tickets_count']),
      totalAmount: readReportString(json['total_amount']),
      currency: readReportString(json['currency']),
      reason: readReportNullableString(json['reason']),
      rejectionReason: readReportNullableString(json['rejection_reason']),
      requestedByName: readReportNullableString(json['requested_by_name']),
      reviewedByName: readReportNullableString(json['reviewed_by_name']),
      appliedByName: readReportNullableString(json['applied_by_name']),
      reviewedAt: readReportDateTime(json['reviewed_at']),
      appliedAt: readReportDateTime(json['applied_at']),
      approvedAt: readReportDateTime(json['approved_at']),
      rejectedAt: readReportDateTime(json['rejected_at']),
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
