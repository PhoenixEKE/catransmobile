class CatalogStation {
  final String id;
  final String name;

  const CatalogStation({
    required this.id,
    required this.name,
  });

  factory CatalogStation.fromJson(Map<String, dynamic> json) {
    return CatalogStation(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
