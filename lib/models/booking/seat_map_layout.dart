class SeatMapLayout {
  final String id;
  final String name;
  final int rows;
  final int columns;

  const SeatMapLayout({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
  });

  factory SeatMapLayout.fromJson(Map<String, dynamic> json) {
    return SeatMapLayout(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rows: _readInt(json['rows']),
      columns: _readInt(json['columns']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rows': rows,
        'columns': columns,
      };

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
