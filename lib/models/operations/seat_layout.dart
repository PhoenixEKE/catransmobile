class SeatLayout {
  final String id;
  final String name;
  final int totalSeats;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SeatLayout({
    required this.id,
    required this.name,
    required this.totalSeats,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'total_seats': totalSeats,
    'description': description,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SeatLayout.fromJson(Map<String, dynamic> json) => SeatLayout(
    id: json['id'],
    name: json['name'],
    totalSeats: json['total_seats'],
    description: json['description'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}