class CatalogDestination {
  final String id;
  final String name;

  const CatalogDestination({
    required this.id,
    required this.name,
  });

  factory CatalogDestination.fromJson(Map<String, dynamic> json) {
    return CatalogDestination(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
