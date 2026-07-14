import 'package:catrans_app/models/booking/seat_hold_response.dart';
import 'package:catrans_app/models/catalog/selected_departure_context.dart';

class SelectedSeatHoldContext {
  final SelectedDepartureContext departureContext;
  final List<SeatHoldResponse> holds;
  final List<int> seatNumbers;
  final int passengerCount;
  final DateTime? expiresAt;

  const SelectedSeatHoldContext({
    required this.departureContext,
    required this.holds,
    required this.seatNumbers,
    required this.passengerCount,
    this.expiresAt,
  });

  List<String> get holdIds => holds.map((hold) => hold.id).toList();

  bool get hasHolds => holds.isNotEmpty;

  DateTime? get firstExpiresAt =>
      expiresAt ?? (holds.isNotEmpty ? holds.first.expiresAt : null);

  bool get isManualSelection => seatNumbers.isNotEmpty;

  bool get isAutomaticSelection => seatNumbers.isEmpty;
}
