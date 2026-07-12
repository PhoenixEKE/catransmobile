import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/route.dart';
import 'package:catrans_app/models/transport/service_class.dart';

class Schedule {
  final String id;
  final Station station;
  final Route? route;
  final ServiceClass? serviceClass;
  final String departureTimeRaw;
  final DateTime? departureTime;
  final String? routeNote;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    required this.id,
    required this.station,
    this.route,
    this.serviceClass,
    required this.departureTimeRaw,
    this.departureTime,
    this.routeNote,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTime => departureTime != null
      ? '${departureTime!.hour.toString().padLeft(2, '0')}:${departureTime!.minute.toString().padLeft(2, '0')}'
      : departureTimeRaw;

  Map<String, dynamic> toJson() => {
    'id': id,
    'station': station.toJson(),
    'route': route?.toJson(),
    'service_class': serviceClass?.toJson(),
    'departure_time_raw': departureTimeRaw,
    'departure_time': departureTime?.toIso8601String(),
    'route_note': routeNote,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'],
    station: Station.fromJson(json['station']),
    route: json['route'] != null ? Route.fromJson(json['route']) : null,
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    departureTimeRaw: json['departure_time_raw'],
    departureTime: json['departure_time'] != null
        ? DateTime.parse(json['departure_time'])
        : null,
    routeNote: json['route_note'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}