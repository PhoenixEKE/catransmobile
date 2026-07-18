import 'package:catrans_app/models/station/reports/station_cancellation.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';

class StationCancellationDetail extends StationCancellation {
  final StationReportActor? requestedBy;
  final StationReportActor? reviewedBy;
  final StationReportActor? appliedBy;
  final StationCancellationTicketSummary tickets;
  final StationReportReservationSummary? reservation;
  final List<StationCancellationPaymentSummary> payments;
  final StationCancellationConsequences consequences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StationCancellationDetail({
    required super.id,
    required super.reference,
    required super.status,
    required super.statusLabel,
    required super.channel,
    required super.channelLabel,
    super.requestedAt,
    required super.reservationId,
    required super.reservationReference,
    super.customerName,
    required super.customerPhone,
    required super.travelersCount,
    required super.ticketsCount,
    required super.totalAmount,
    required super.currency,
    super.reason,
    super.rejectionReason,
    super.requestedByName,
    super.reviewedByName,
    super.appliedByName,
    super.reviewedAt,
    super.appliedAt,
    super.approvedAt,
    super.rejectedAt,
    super.cancelledAt,
    required super.availableActions,
    required super.eligibility,
    this.requestedBy,
    this.reviewedBy,
    this.appliedBy,
    required this.tickets,
    this.reservation,
    required this.payments,
    required this.consequences,
    this.createdAt,
    this.updatedAt,
  });

  factory StationCancellationDetail.fromJson(Map<String, dynamic> json) {
    final base = StationCancellation.fromJson(json);
    return StationCancellationDetail(
      id: base.id,
      reference: base.reference,
      status: base.status,
      statusLabel: base.statusLabel,
      channel: base.channel,
      channelLabel: base.channelLabel,
      requestedAt: base.requestedAt,
      reservationId: base.reservationId,
      reservationReference: base.reservationReference,
      customerName: base.customerName,
      customerPhone: base.customerPhone,
      travelersCount: base.travelersCount,
      ticketsCount: base.ticketsCount,
      totalAmount: base.totalAmount,
      currency: base.currency,
      reason: base.reason,
      rejectionReason: base.rejectionReason,
      requestedByName: base.requestedByName,
      reviewedByName: base.reviewedByName,
      appliedByName: base.appliedByName,
      reviewedAt: base.reviewedAt,
      appliedAt: base.appliedAt,
      approvedAt: base.approvedAt,
      rejectedAt: base.rejectedAt,
      cancelledAt: base.cancelledAt,
      availableActions: base.availableActions,
      eligibility: base.eligibility,
      requestedBy: json['requested_by'] == null
          ? null
          : StationReportActor.fromJson(readReportObject(json['requested_by'])),
      reviewedBy: json['reviewed_by'] == null
          ? null
          : StationReportActor.fromJson(readReportObject(json['reviewed_by'])),
      appliedBy: json['applied_by'] == null
          ? null
          : StationReportActor.fromJson(readReportObject(json['applied_by'])),
      tickets: StationCancellationTicketSummary.fromJson(
        readReportObject(json['tickets']),
      ),
      reservation: json['reservation'] == null
          ? null
          : StationReportReservationSummary.fromJson(
              readReportObject(json['reservation']),
            ),
      payments: readReportList(json['payments'])
          .map((payment) => StationCancellationPaymentSummary.fromJson(
                readReportObject(payment),
              ))
          .toList(),
      consequences: StationCancellationConsequences.fromJson(
        readReportObject(json['consequences']),
      ),
      createdAt: readReportDateTime(json['created_at']),
      updatedAt: readReportDateTime(json['updated_at']),
    );
  }
}

class StationCancellationTicketSummary {
  final int total;
  final int issued;
  final int used;
  final int cancelled;

  const StationCancellationTicketSummary({
    required this.total,
    required this.issued,
    required this.used,
    required this.cancelled,
  });

  const StationCancellationTicketSummary.empty()
      : total = 0,
        issued = 0,
        used = 0,
        cancelled = 0;

  factory StationCancellationTicketSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationCancellationTicketSummary(
      total: readReportInt(json['total']),
      issued: readReportInt(json['issued']),
      used: readReportInt(json['used']),
      cancelled: readReportInt(json['cancelled']),
    );
  }
}

class StationCancellationPaymentSummary {
  final String id;
  final String reference;
  final String status;
  final String statusLabel;
  final String amount;
  final String currency;
  final String provider;
  final DateTime? paidAt;

  const StationCancellationPaymentSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.amount,
    required this.currency,
    required this.provider,
    this.paidAt,
  });

  String get displayAmount => '$amount $currency'.trim();

  factory StationCancellationPaymentSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationCancellationPaymentSummary(
      id: readReportString(json['id']),
      reference: readReportString(json['reference']),
      status: readReportString(json['status']),
      statusLabel: readReportString(json['status_label']),
      amount: readReportString(json['amount']),
      currency: readReportString(json['currency']),
      provider: readReportString(json['provider']),
      paidAt: readReportDateTime(json['paid_at']),
    );
  }
}

class StationCancellationConsequences {
  final String? cancellationScope;
  final int ticketsToCancel;
  final bool refundAutomatic;
  final bool partialCancellationSupported;
  final bool fareAdjustmentSupported;

  const StationCancellationConsequences({
    this.cancellationScope,
    required this.ticketsToCancel,
    required this.refundAutomatic,
    required this.partialCancellationSupported,
    required this.fareAdjustmentSupported,
  });

  const StationCancellationConsequences.empty()
      : cancellationScope = null,
        ticketsToCancel = 0,
        refundAutomatic = false,
        partialCancellationSupported = false,
        fareAdjustmentSupported = false;

  factory StationCancellationConsequences.fromJson(Map<String, dynamic> json) {
    return StationCancellationConsequences(
      cancellationScope: readReportNullableString(json['cancellation_scope']),
      ticketsToCancel: readReportInt(json['tickets_to_cancel']),
      refundAutomatic: readReportBool(json['refund_automatic']),
      partialCancellationSupported:
          readReportBool(json['partial_cancellation_supported']),
      fareAdjustmentSupported:
          readReportBool(json['fare_adjustment_supported']),
    );
  }
}

class StationCancellationApplyResult {
  final StationCancellationDetail cancellation;
  final StationCancellationApplySummary summary;

  const StationCancellationApplyResult({
    required this.cancellation,
    required this.summary,
  });

  factory StationCancellationApplyResult.fromJson(Map<String, dynamic> json) {
    return StationCancellationApplyResult(
      cancellation: StationCancellationDetail.fromJson(
        readReportObject(json['cancellation']),
      ),
      summary: StationCancellationApplySummary.fromJson(
        readReportObject(json['summary']),
      ),
    );
  }
}

class StationCancellationApplySummary {
  final int cancelledTickets;
  final int cancelledItems;
  final int releasedSeats;
  final dynamic loyaltyReversal;
  final dynamic loyaltyRestoration;

  const StationCancellationApplySummary({
    required this.cancelledTickets,
    required this.cancelledItems,
    required this.releasedSeats,
    this.loyaltyReversal,
    this.loyaltyRestoration,
  });

  factory StationCancellationApplySummary.fromJson(Map<String, dynamic> json) {
    return StationCancellationApplySummary(
      cancelledTickets: readReportInt(json['cancelled_tickets']),
      cancelledItems: readReportInt(json['cancelled_items']),
      releasedSeats: readReportInt(json['released_seats']),
      loyaltyReversal: json['loyalty_reversal'],
      loyaltyRestoration: json['loyalty_restoration'],
    );
  }
}
