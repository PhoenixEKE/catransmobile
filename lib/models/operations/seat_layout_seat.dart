import 'package:catrans_app/models/operations/seat_layout.dart';

enum SeatType { standard, vip, driver, door, empty }

class SeatLayoutSeat {
  final String id;
  final SeatLayout seatLayout;
  final int seatNumber;
  final String? label;
  final int rowNumber;
  final int columnNumber;
  final int? positionX;
  final int? positionY;
  final SeatType seatType;
  final String? displayLabel;
  final bool isSelectable;
  final bool isWindow;
  final bool isAisle;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SeatLayoutSeat({
    required this.id,
    required this.seatLayout,
    required this.seatNumber,
    this.label,
    this.rowNumber = 1,
    this.columnNumber = 1,
    this.positionX,
    this.positionY,
    this.seatType = SeatType.standard,
    this.displayLabel,
    this.isSelectable = true,
    this.isWindow = false,
    this.isAisle = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'seat_layout': seatLayout.toJson(),
    'seat_number': seatNumber,
    'label': label,
    'row_number': rowNumber,
    'column_number': columnNumber,
    'position_x': positionX,
    'position_y': positionY,
    'seat_type': seatType.name,
    'display_label': displayLabel,
    'is_selectable': isSelectable,
    'is_window': isWindow,
    'is_aisle': isAisle,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory SeatLayoutSeat.fromJson(Map<String, dynamic> json) => SeatLayoutSeat(
    id: json['id'],
    seatLayout: SeatLayout.fromJson(json['seat_layout']),
    seatNumber: json['seat_number'],
    label: json['label'],
    rowNumber: json['row_number'] ?? 1,
    columnNumber: json['column_number'] ?? 1,
    positionX: json['position_x'],
    positionY: json['position_y'],
    seatType: SeatType.values.firstWhere(
      (e) => e.name == json['seat_type'],
      orElse: () => SeatType.standard,
    ),
    displayLabel: json['display_label'],
    isSelectable: json['is_selectable'] ?? true,
    isWindow: json['is_window'] ?? false,
    isAisle: json['is_aisle'] ?? false,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}