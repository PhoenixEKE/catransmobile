import 'package:catrans_app/models/transport/station.dart';
import 'package:catrans_app/models/transport/schedule.dart';
import 'package:catrans_app/models/transport/service_class.dart';
import 'package:catrans_app/models/operations/seat_layout.dart';

class DepartureTemplate {
  final String id;
  final Station station;
  final Schedule? schedule;
  final ServiceClass? serviceClass;
  final SeatLayout? seatLayout;
  final String departureTimeRaw;
  final DateTime? departureTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepartureTemplate({
    required this.id,
    required this.station,
    this.schedule,
    this.serviceClass,
    this.seatLayout,
    required this.departureTimeRaw,
    this.departureTime,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'station': station.toJson(),
    'schedule': schedule?.toJson(),
    'service_class': serviceClass?.toJson(),
    'seat_layout': seatLayout?.toJson(),
    'departure_time_raw': departureTimeRaw,
    'departure_time': departureTime?.toIso8601String(),
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory DepartureTemplate.fromJson(Map<String, dynamic> json) => DepartureTemplate(
    id: json['id'],
    station: Station.fromJson(json['station']),
    schedule: json['schedule'] != null ? Schedule.fromJson(json['schedule']) : null,
    serviceClass: json['service_class'] != null ? ServiceClass.fromJson(json['service_class']) : null,
    seatLayout: json['seat_layout'] != null ? SeatLayout.fromJson(json['seat_layout']) : null,
    departureTimeRaw: json['departure_time_raw'],
    departureTime: json['departure_time'] != null
        ? DateTime.parse(json['departure_time'])
        : null,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}