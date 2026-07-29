import 'package:catrans_app/models/transport/company.dart';
import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/city.dart';

class Route {
  final String id;
  final Company company;
  final Station departureStation;
  final City? departureCity;
  final City? destinationCity;
  final String destinationNameSnapshot;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Route({
    required this.id,
    required this.company,
    required this.departureStation,
    this.departureCity,
    this.destinationCity,
    required this.destinationNameSnapshot,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '${departureStation.name} → $destinationNameSnapshot';

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company.toJson(),
    'departure_station': departureStation.toJson(),
    'departure_city': departureCity?.toJson(),
    'destination_city': destinationCity?.toJson(),
    'destination_name_snapshot': destinationNameSnapshot,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Route.fromJson(Map<String, dynamic> json) => Route(
    id: json['id'],
    company: Company.fromJson(json['company']),
    departureStation: Station.fromJson(json['departure_station']),
    departureCity: json['departure_city'] != null ? City.fromJson(json['departure_city']) : null,
    destinationCity: json['destination_city'] != null ? City.fromJson(json['destination_city']) : null,
    destinationNameSnapshot: json['destination_name_snapshot'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}