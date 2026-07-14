class ReservationCreateItem {
  final String? seatHoldId;
  final bool isForCustomer;
  final bool useLoyaltyPoints;
  final String? travelerLastname;
  final String? travelerFirstname;
  final String? travelerPhone;

  const ReservationCreateItem({
    this.seatHoldId,
    this.isForCustomer = true,
    this.useLoyaltyPoints = false,
    this.travelerLastname,
    this.travelerFirstname,
    this.travelerPhone,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'is_for_customer': isForCustomer,
      'use_loyalty_points': useLoyaltyPoints,
    };

    _putIfNotBlank(data, 'seat_hold_id', seatHoldId);
    _putIfNotBlank(data, 'traveler_lastname', travelerLastname);
    _putIfNotBlank(data, 'traveler_firstname', travelerFirstname);
    _putIfNotBlank(data, 'traveler_phone', travelerPhone);

    return data;
  }

  static void _putIfNotBlank(
    Map<String, dynamic> data,
    String key,
    String? value,
  ) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      data[key] = trimmed;
    }
  }
}
