import 'package:catrans_app/models/station/reports/station_cancellation.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';
import 'package:catrans_app/models/station/reports/station_reservation_change.dart';

class StationReservationChangesPage {
  final int count;
  final String? next;
  final String? previous;
  final List<StationReservationChange> results;

  const StationReservationChangesPage({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get isEmpty => results.isEmpty;
  bool get hasNext => next != null && next!.isNotEmpty;
  bool get hasPrevious => previous != null && previous!.isNotEmpty;

  factory StationReservationChangesPage.fromJson(Map<String, dynamic> json) {
    return StationReservationChangesPage(
      count: readReportInt(json['count']),
      next: readReportNullableString(json['next']),
      previous: readReportNullableString(json['previous']),
      results: readReportList(json['results'])
          .map((item) => StationReservationChange.fromJson(
                readReportObject(item),
              ))
          .toList(),
    );
  }
}

class StationCancellationsPage {
  final int count;
  final String? next;
  final String? previous;
  final List<StationCancellation> results;

  const StationCancellationsPage({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get isEmpty => results.isEmpty;
  bool get hasNext => next != null && next!.isNotEmpty;
  bool get hasPrevious => previous != null && previous!.isNotEmpty;

  factory StationCancellationsPage.fromJson(Map<String, dynamic> json) {
    return StationCancellationsPage(
      count: readReportInt(json['count']),
      next: readReportNullableString(json['next']),
      previous: readReportNullableString(json['previous']),
      results: readReportList(json['results'])
          .map((item) => StationCancellation.fromJson(readReportObject(item)))
          .toList(),
    );
  }
}
