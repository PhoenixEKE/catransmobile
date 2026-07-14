import 'package:catrans_app/models/reservation/reservation_create_item.dart';

class CreateEconomyReservationRequest {
  final String departureId;
  final String serviceClassCode;
  final List<ReservationCreateItem> items;

  const CreateEconomyReservationRequest({
    required this.departureId,
    this.serviceClassCode = 'ECONOMIE',
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'departure_id': departureId,
        'service_class_code': serviceClassCode,
        'items': items.map((item) => item.toJson()).toList(),
      };
}
