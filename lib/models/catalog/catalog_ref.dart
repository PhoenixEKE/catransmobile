class CatalogStationRef {
  final String id;
  final String name;

  const CatalogStationRef({
    required this.id,
    required this.name,
  });

  factory CatalogStationRef.fromJson(Map<String, dynamic> json) {
    return CatalogStationRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class CatalogDestinationRef {
  final String id;
  final String name;

  const CatalogDestinationRef({
    required this.id,
    required this.name,
  });

  factory CatalogDestinationRef.fromJson(Map<String, dynamic> json) {
    return CatalogDestinationRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class CatalogRouteRef {
  final String? id;
  final String? label;

  const CatalogRouteRef({
    this.id,
    this.label,
  });

  factory CatalogRouteRef.fromJson(Map<String, dynamic> json) {
    return CatalogRouteRef(
      id: json['id'] as String?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };
}
