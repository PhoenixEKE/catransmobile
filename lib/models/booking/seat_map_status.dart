class SeatMapStatus {
  final String code;
  final String label;

  const SeatMapStatus({
    required this.code,
    required this.label,
  });

  factory SeatMapStatus.fromJson(Map<String, dynamic> json) {
    return SeatMapStatus(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
      };
}
