import 'package:catrans_app/models/catalog/catalog_booking_policy.dart';
import 'package:catrans_app/models/catalog/catalog_fare.dart';
import 'package:catrans_app/models/catalog/catalog_ref.dart';
import 'package:catrans_app/models/catalog/catalog_seat_summary.dart';
import 'package:catrans_app/models/catalog/catalog_service_class_ref.dart';
import 'package:catrans_app/models/catalog/catalog_status.dart';

class CatalogDeparture {
  final String id;
  final CatalogStatus status;
  final CatalogStationRef station;
  final CatalogDestinationRef destination;
  final CatalogRouteRef route;
  final DateTime departureDate;
  final String departureTime;
  final CatalogServiceClassRef serviceClass;
  final CatalogFare fare;
  final CatalogSeatSummary seats;
  final CatalogBookingPolicy bookingPolicy;

  const CatalogDeparture({
    required this.id,
    required this.status,
    required this.station,
    required this.destination,
    required this.route,
    required this.departureDate,
    required this.departureTime,
    required this.serviceClass,
    required this.fare,
    required this.seats,
    required this.bookingPolicy,
  });

  factory CatalogDeparture.fromJson(Map<String, dynamic> json) {
    return CatalogDeparture(
      id: json['id'] as String,
      status: CatalogStatus.fromJson(_readObject(json['status'])),
      station: CatalogStationRef.fromJson(_readObject(json['station'])),
      destination: CatalogDestinationRef.fromJson(
        _readObject(json['destination']),
      ),
      route: CatalogRouteRef.fromJson(_readObject(json['route'])),
      departureDate: DateTime.parse(json['departure_date'] as String),
      departureTime: json['departure_time'] as String? ?? '',
      serviceClass: CatalogServiceClassRef.fromJson(
        _readObject(json['service_class']),
      ),
      fare: CatalogFare.fromJson(_readObject(json['fare'])),
      seats: CatalogSeatSummary.fromJson(_readObject(json['seats'])),
      bookingPolicy: CatalogBookingPolicy.fromJson(
        _readObject(json['booking_policy']),
      ),
    );
  }

  bool get canBook => bookingPolicy.salesOpen && seats.hasAvailableSeats;

  bool get isEconomy => serviceClass.isEconomy;

  bool get isPrestige => serviceClass.isPrestige;

  String get apiDate {
    final year = departureDate.year.toString().padLeft(4, '0');
    final month = departureDate.month.toString().padLeft(2, '0');
    final day = departureDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.toJson(),
        'station': station.toJson(),
        'destination': destination.toJson(),
        'route': route.toJson(),
        'departure_date': apiDate,
        'departure_time': departureTime,
        'service_class': serviceClass.toJson(),
        'fare': fare.toJson(),
        'seats': seats.toJson(),
        'booking_policy': bookingPolicy.toJson(),
      };

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}
