import 'package:catrans_app/models/booking/seat_map_refs.dart';
import 'package:catrans_app/models/booking/seat_map_status.dart';

class SeatMapDeparture {
  final String id;
  final SeatMapStatus status;
  final SeatMapStationRef station;
  final String destination;
  final String departureDate;
  final String departureTime;
  final SeatMapServiceClassRef serviceClass;

  const SeatMapDeparture({
    required this.id,
    required this.status,
    required this.station,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.serviceClass,
  });

  factory SeatMapDeparture.fromJson(Map<String, dynamic> json) {
    return SeatMapDeparture(
      id: json['id'] as String? ?? '',
      status: SeatMapStatus.fromJson(_readObject(json['status'])),
      station: SeatMapStationRef.fromJson(_readObject(json['station'])),
      destination: json['destination'] as String? ?? '',
      departureDate: json['departure_date'] as String? ?? '',
      departureTime: json['departure_time'] as String? ?? '',
      serviceClass: SeatMapServiceClassRef.fromJson(
        _readObject(json['service_class']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.toJson(),
        'station': station.toJson(),
        'destination': destination,
        'departure_date': departureDate,
        'departure_time': departureTime,
        'service_class': serviceClass.toJson(),
      };

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
