class SeatMapSeatVisual {
  final int rowNumber;
  final int columnNumber;
  final int? positionX;
  final int? positionY;
  final String seatType;
  final bool isWindow;
  final bool isAisle;

  const SeatMapSeatVisual({
    required this.rowNumber,
    required this.columnNumber,
    this.positionX,
    this.positionY,
    required this.seatType,
    required this.isWindow,
    required this.isAisle,
  });

  factory SeatMapSeatVisual.fromJson(Map<String, dynamic> json) {
    return SeatMapSeatVisual(
      rowNumber: _readInt(json['row_number']) ?? 1,
      columnNumber: _readInt(json['column_number']) ?? 1,
      positionX: _readInt(json['position_x']),
      positionY: _readInt(json['position_y']),
      seatType: json['seat_type'] as String? ?? 'standard',
      isWindow: json['is_window'] as bool? ?? false,
      isAisle: json['is_aisle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'row_number': rowNumber,
        'column_number': columnNumber,
        'position_x': positionX,
        'position_y': positionY,
        'seat_type': seatType,
        'is_window': isWindow,
        'is_aisle': isAisle,
      };

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
