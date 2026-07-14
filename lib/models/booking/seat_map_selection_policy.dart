class SeatMapSelectionPolicy {
  final bool allowed;
  final String mode;
  final String message;

  const SeatMapSelectionPolicy({
    required this.allowed,
    required this.mode,
    required this.message,
  });

  factory SeatMapSelectionPolicy.fromJson(Map<String, dynamic> json) {
    return SeatMapSelectionPolicy(
      allowed: json['allowed'] as bool? ?? false,
      mode: json['mode'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  bool get isManual => mode == 'manual';

  bool get isAutomatic => mode == 'automatic';

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'mode': mode,
        'message': message,
      };
}
