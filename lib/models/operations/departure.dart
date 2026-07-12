import 'package:catrans_app/models/operations/departure_template.dart';
import 'package:catrans_app/models/transport/route.dart';
import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/service_class.dart';
import 'package:catrans_app/models/operations/seat_layout.dart';

class Departure {
  final String id;
  final DepartureTemplate departureTemplate;
  final Route? route;
  final Station station;
  final ServiceClass? serviceClass;
  final SeatLayout? seatLayout;
  final DateTime departureDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Departure({
    required this.id,
    required this.departureTemplate,
    this.route,
    required this.station,
    this.serviceClass,
    this.seatLayout,
    required this.departureDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayDate => '${departureDate.day}/${departureDate.month}/${departureDate.year}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'departure_template': departureTemplate.toJson(),
    'route': route?.toJson(),
    'station': station.toJson(),
    'service_class': serviceClass?.toJson(),
    'seat_layout': seatLayout?.toJson(),
    'departure_date': departureDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Departure.fromJson(Map<String, dynamic> json) => Departure(
    id: json['id'],
    departureTemplate: DepartureTemplate.fromJson(json['departure_template']),
    route: json['route'] != null ? Route.fromJson(json['route']) : null,
    station: Station.fromJson(json['station']),
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    seatLayout: json['seat_layout'] != null ? SeatLayout.fromJson(json['seat_layout']) : null,
    departureDate: DateTime.parse(json['departure_date']),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}