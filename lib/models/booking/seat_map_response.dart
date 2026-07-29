import 'package:catrans_app/models/booking/seat_map_counts.dart';
import 'package:catrans_app/models/booking/seat_map_departure.dart';
import 'package:catrans_app/models/booking/seat_map_layout.dart';
import 'package:catrans_app/models/booking/seat_map_seat.dart';
import 'package:catrans_app/models/booking/seat_map_selection_policy.dart';

class SeatMapResponse {
  final SeatMapDeparture departure;
  final SeatMapSelectionPolicy seatSelection;
  final SeatMapLayout layout;
  final SeatMapCounts counts;
  final List<SeatMapSeat> seats;

  const SeatMapResponse({
    required this.departure,
    required this.seatSelection,
    required this.layout,
    required this.counts,
    required this.seats,
  });

  factory SeatMapResponse.fromJson(Map<String, dynamic> json) {
    final seatsJson = json['seats'] is List ? json['seats'] as List : const [];

    return SeatMapResponse(
      departure: SeatMapDeparture.fromJson(_readObject(json['departure'])),
      seatSelection: SeatMapSelectionPolicy.fromJson(
        _readObject(json['seat_selection']),
      ),
      layout: SeatMapLayout.fromJson(_readObject(json['layout'])),
      counts: SeatMapCounts.fromJson(_readObject(json['counts'])),
      seats: seatsJson
          .map((seat) => SeatMapSeat.fromJson(_readObject(seat)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'departure': departure.toJson(),
        'seat_selection': seatSelection.toJson(),
        'layout': layout.toJson(),
        'counts': counts.toJson(),
        'seats': seats.map((seat) => seat.toJson()).toList(),
      };

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
