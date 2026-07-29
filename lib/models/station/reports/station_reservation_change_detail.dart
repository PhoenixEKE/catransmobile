import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change.dart';

class StationReservationChangeDetail extends StationReservationChange {
  final StationReportActor? requestedBy;
  final StationReportActor? reviewedBy;
  final StationReportActor? appliedBy;
  final List<StationReservationChangeItem> items;
  final StationReportReservationSummary? reservation;
  final StationReportFlags flags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StationReservationChangeDetail({
    required super.id,
    required super.reference,
    required super.status,
    required super.statusLabel,
    required super.changeType,
    required super.changeTypeLabel,
    super.requestedAt,
    required super.reservationId,
    required super.reservationReference,
    super.customerName,
    required super.customerPhone,
    required super.itemsCount,
    super.currentDepartureSummary,
    super.requestedDepartureSummary,
    super.reason,
    super.rejectionReason,
    super.requestedByName,
    super.reviewedByName,
    super.appliedByName,
    super.reviewedAt,
    super.appliedAt,
    super.cancelledAt,
    required super.availableActions,
    required super.eligibility,
    this.requestedBy,
    this.reviewedBy,
    this.appliedBy,
    required this.items,
    this.reservation,
    required this.flags,
    this.createdAt,
    this.updatedAt,
  });

  factory StationReservationChangeDetail.fromJson(Map<String, dynamic> json) {
    final base = StationReservationChange.fromJson(json);
    return StationReservationChangeDetail(
      id: base.id,
      reference: base.reference,
      status: base.status,
      statusLabel: base.statusLabel,
      changeType: base.changeType,
      changeTypeLabel: base.changeTypeLabel,
      requestedAt: base.requestedAt,
      reservationId: base.reservationId,
      reservationReference: base.reservationReference,
      customerName: base.customerName,
      customerPhone: base.customerPhone,
      itemsCount: base.itemsCount,
      currentDepartureSummary: base.currentDepartureSummary,
      requestedDepartureSummary: base.requestedDepartureSummary,
      reason: base.reason,
      rejectionReason: base.rejectionReason,
      requestedByName: base.requestedByName,
      reviewedByName: base.reviewedByName,
      appliedByName: base.appliedByName,
      reviewedAt: base.reviewedAt,
      appliedAt: base.appliedAt,
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
      items: readReportList(json['items'])
          .map((item) => StationReservationChangeItem.fromJson(
                readReportObject(item),
              ))
          .toList(),
      reservation: json['reservation'] == null
          ? null
          : StationReportReservationSummary.fromJson(
              readReportObject(json['reservation']),
            ),
      flags: StationReportFlags.fromJson(readReportObject(json['flags'])),
      createdAt: readReportDateTime(json['created_at']),
      updatedAt: readReportDateTime(json['updated_at']),
    );
  }
}

class StationReservationChangeItem {
  final String id;
  final String reservationItemId;
  final StationReportTraveler traveler;
  final StationReportDepartureSummary? oldDeparture;
  final StationReportDepartureSummary? newDeparture;
  final int? oldSeatNumber;
  final int? newSeatNumber;
  final StationReportTicketRef? oldTicket;
  final String oldUnitPrice;
  final String newUnitPrice;
  final String fareDifference;
  final String? notes;

  const StationReservationChangeItem({
    required this.id,
    required this.reservationItemId,
    required this.traveler,
    this.oldDeparture,
    this.newDeparture,
    this.oldSeatNumber,
    this.newSeatNumber,
    this.oldTicket,
    required this.oldUnitPrice,
    required this.newUnitPrice,
    required this.fareDifference,
    this.notes,
  });

  bool get hasSeatChange => oldSeatNumber != newSeatNumber;

  factory StationReservationChangeItem.fromJson(Map<String, dynamic> json) {
    return StationReservationChangeItem(
      id: readReportString(json['id']),
      reservationItemId: readReportString(json['reservation_item_id']),
      traveler: StationReportTraveler.fromJson(
        readReportObject(json['traveler']),
      ),
      oldDeparture: json['old_departure'] == null
          ? null
          : StationReportDepartureSummary.fromJson(
              readReportObject(json['old_departure']),
            ),
      newDeparture: json['new_departure'] == null
          ? null
          : StationReportDepartureSummary.fromJson(
              readReportObject(json['new_departure']),
            ),
      oldSeatNumber: _readNullableInt(json['old_seat_number']),
      newSeatNumber: _readNullableInt(json['new_seat_number']),
      oldTicket: json['old_ticket'] == null
          ? null
          : StationReportTicketRef.fromJson(
              readReportObject(json['old_ticket']),
            ),
      oldUnitPrice: readReportString(json['old_unit_price']),
      newUnitPrice: readReportString(json['new_unit_price']),
      fareDifference: readReportString(json['fare_difference']),
      notes: readReportNullableString(json['notes']),
    );
  }
}

int? _readNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}
