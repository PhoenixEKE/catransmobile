import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/transport/station.dart';

enum InternalRole {
  station_agent,
  station_manager,
  cashier,
  support,
  accounting,
  director,
  marketing,
  admin,
  legacy_unknown
}

class InternalProfile {
  final String id;
  final User user;
  final Station? station;
  final InternalRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  InternalProfile({
    required this.id,
    required this.user,
    this.station,
    this.role = InternalRole.station_agent,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == InternalRole.admin || role == InternalRole.director;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': user.toJson(),
    'station_id': station?.id,
    'role': role.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory InternalProfile.fromJson(Map<String, dynamic> json) => InternalProfile(
    id: json['id'],
    user: User.fromJson(json['user']),
    station: json['station_id'] != null ? Station.fromJson(json['station']) : null,
    role: InternalRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => InternalRole.station_agent,
    ),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}