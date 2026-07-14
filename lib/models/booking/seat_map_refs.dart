class SeatMapStationRef {
  final String id;
  final String name;

  const SeatMapStationRef({
    required this.id,
    required this.name,
  });

  factory SeatMapStationRef.fromJson(Map<String, dynamic> json) {
    return SeatMapStationRef(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class SeatMapServiceClassRef {
  final String id;
  final String code;
  final String name;

  const SeatMapServiceClassRef({
    required this.id,
    required this.code,
    required this.name,
  });

  factory SeatMapServiceClassRef.fromJson(Map<String, dynamic> json) {
    return SeatMapServiceClassRef(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  bool get isEconomy => code.toUpperCase() == 'ECONOMIE';

  bool get isPrestige => code.toUpperCase() == 'PRESTIGE';

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
      };
}
