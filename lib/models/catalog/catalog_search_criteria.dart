import 'package:catrans_app/models/catalog/catalog_destination.dart';
import 'package:catrans_app/models/catalog/catalog_station.dart';
import 'package:catrans_app/models/catalog/catalog_travel_date.dart';

class CatalogSearchCriteria {
  final CatalogStation station;
  final CatalogDestination destination;
  final CatalogTravelDate travelDate;

  const CatalogSearchCriteria({
    required this.station,
    required this.destination,
    required this.travelDate,
  });

  String get stationId => station.id;

  String get stationName => station.name;

  String get destinationCityId => destination.id;

  String get destinationName => destination.name;

  DateTime get date => travelDate.date;

  String get apiDate => travelDate.apiDate;
}