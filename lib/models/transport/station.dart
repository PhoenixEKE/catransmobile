import 'package:catrans_app/models/transport/company.dart';
import 'package:catrans_app/models/transport/city.dart';

class Station {
  final String id;
  final Company company;
  final City? city;
  final String name;
  final String normalizedName;
  final String? cityNameSnapshot;
  final String? code;
  final String? phoneLine;
  final String? representative;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Station({
    required this.id,
    required this.company,
    this.city,
    required this.name,
    required this.normalizedName,
    this.cityNameSnapshot,
    this.code,
    this.phoneLine,
    this.representative,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$name (${city?.name ?? cityNameSnapshot ?? ''})';

  Map<String, dynamic> toJson() => {
    'id': id,
    'company': company.toJson(),
    'city': city?.toJson(),
    'name': name,
    'normalized_name': normalizedName,
    'city_name_snapshot': cityNameSnapshot,
    'code': code,
    'phone_line': phoneLine,
    'representative': representative,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'],
    company: Company.fromJson(json['company']),
    city: json['city'] != null ? City.fromJson(json['city']) : null,
    name: json['name'],
    normalizedName: json['normalized_name'],
    cityNameSnapshot: json['city_name_snapshot'],
    code: json['code'],
    phoneLine: json['phone_line'],
    representative: json['representative'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}