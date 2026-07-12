class Company {
  final String id;
  final String name;
  final String? code;
  final String? customerServicePhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.code,
    this.customerServicePhone,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'customer_service_phone': customerServicePhone,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'],
    name: json['name'],
    code: json['code'],
    customerServicePhone: json['customer_service_phone'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}