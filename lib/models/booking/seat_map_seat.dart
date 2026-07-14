import 'package:catrans_app/models/booking/seat_map_seat_blocked.dart';
import 'package:catrans_app/models/booking/seat_map_seat_visual.dart';
import 'package:catrans_app/models/booking/seat_map_status.dart';

class SeatMapSeat {
  final String id;
  final int seatNumber;
  final String displayLabel;
  final SeatMapStatus status;
  final bool isAvailable;
  final bool isSelectable;
  final bool isInServiceClassZone;
  final bool canSelect;
  final String? selectionBlockedReason;
  final SeatMapSeatVisual visual;
  final SeatMapSeatBlocked blocked;

  const SeatMapSeat({
    required this.id,
    required this.seatNumber,
    required this.displayLabel,
    required this.status,
    required this.isAvailable,
    required this.isSelectable,
    this.isInServiceClassZone = true,
    required this.canSelect,
    this.selectionBlockedReason,
    required this.visual,
    required this.blocked,
  });

  factory SeatMapSeat.fromJson(Map<String, dynamic> json) {
    return SeatMapSeat(
      id: json['id'] as String? ?? '',
      seatNumber: _readInt(json['seat_number']),
      displayLabel: json['display_label'] as String? ?? '',
      status: SeatMapStatus.fromJson(_readObject(json['status'])),
      isAvailable: json['is_available'] as bool? ?? false,
      isSelectable: json['is_selectable'] as bool? ?? false,
      isInServiceClassZone:
          json['is_in_service_class_zone'] as bool? ?? true,
      canSelect: json['can_select'] as bool? ?? false,
      selectionBlockedReason: json['selection_blocked_reason'] as String?,
      visual: SeatMapSeatVisual.fromJson(_readObject(json['visual'])),
      blocked: SeatMapSeatBlocked.fromJson(_readObject(json['blocked'])),
    );
  }

  bool get isHeld => status.code == 'held';

  bool get isReserved => status.code == 'reserved';

  bool get isBlocked => status.code == 'blocked';

  bool get isOutOfServiceClassZone => !isInServiceClassZone;

  bool get isAvailableForSelection =>
      isAvailable && isSelectable && canSelect && isInServiceClassZone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'seat_number': seatNumber,
        'display_label': displayLabel,
        'status': status.toJson(),
        'is_available': isAvailable,
        'is_selectable': isSelectable,
        'is_in_service_class_zone': isInServiceClassZone,
        'can_select': canSelect,
        'selection_blocked_reason': selectionBlockedReason,
        'visual': visual.toJson(),
        'blocked': blocked.toJson(),
      };

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, dynamic> _readObject(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
