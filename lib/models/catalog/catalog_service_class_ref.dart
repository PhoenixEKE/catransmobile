class CatalogServiceClassRef {
  final String id;
  final String code;
  final String name;

  const CatalogServiceClassRef({
    required this.id,
    required this.code,
    required this.name,
  });

  factory CatalogServiceClassRef.fromJson(Map<String, dynamic> json) {
    return CatalogServiceClassRef(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  bool get isEconomy => code.toUpperCase() == 'ECONOMIE';

  bool get isPrestige => code.toUpperCase() == 'PRESTIGE';

  String get uiCode {
    if (isEconomy) return 'economie';
    if (isPrestige) return 'prestige';
    return code.toLowerCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
      };
}
