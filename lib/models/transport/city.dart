class City {
  final String id;
  final String name;
  final String normalizedName;
  final String? country;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  City({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.country,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'normalized_name': normalizedName,
    'country': country,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'],
    name: json['name'],
    normalizedName: json['normalized_name'],
    country: json['country'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}