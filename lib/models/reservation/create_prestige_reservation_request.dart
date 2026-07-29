import 'package:catrans_app/models/reservation/reservation_create_item.dart';

class CreatePrestigeReservationRequest {
  final List<ReservationCreateItem> items;

  const CreatePrestigeReservationRequest({
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
      };
}
