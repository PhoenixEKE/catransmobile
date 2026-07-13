import 'package:catrans_app/models/catalog/catalog_departure.dart';
import 'package:catrans_app/models/catalog/catalog_search_criteria.dart';

class SelectedDepartureContext {
  final CatalogSearchCriteria searchCriteria;
  final CatalogDeparture departure;
  final String selectedClass;
  final int passengerCount;
  final int loyaltyPointsPerPassenger;

  const SelectedDepartureContext({
    required this.searchCriteria,
    required this.departure,
    required this.selectedClass,
    required this.passengerCount,
    required this.loyaltyPointsPerPassenger,
  });

  String get departureId => departure.id;

  String get serviceClassId => departure.serviceClass.id;

  String get serviceClassCode => departure.serviceClass.code;

  String get fareId => departure.fare.id;

  String get fareAmount => departure.fare.amount;

  int get availableSeats => departure.seats.available;

  bool get salesOpen => departure.bookingPolicy.salesOpen;
}
