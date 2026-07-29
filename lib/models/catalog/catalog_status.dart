class CatalogStatus {
  final String code;
  final String label;

  const CatalogStatus({
    required this.code,
    required this.label,
  });

  factory CatalogStatus.fromJson(Map<String, dynamic> json) {
    return CatalogStatus(
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'label': label,
      };
}
