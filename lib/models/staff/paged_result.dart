typedef JsonMap = Map<String, dynamic>;

class PagedResult<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PagedResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  bool get hasNext => next != null && next!.isNotEmpty;
  bool get hasPrevious => previous != null && previous!.isNotEmpty;

  factory PagedResult.fromJson(
    dynamic json,
    T Function(JsonMap json) fromJson,
  ) {
    if (json is List) {
      final results = json
          .whereType<Map>()
          .map((item) => fromJson(JsonMap.from(item)))
          .toList();
      return PagedResult<T>(
        count: results.length,
        next: null,
        previous: null,
        results: results,
      );
    }

    if (json is Map) {
      final map = JsonMap.from(json);
      final rawResults = map['results'];
      final list = rawResults is List ? rawResults : const [];
      return PagedResult<T>(
        count: _readInt(map['count']) ?? list.length,
        next: map['next']?.toString(),
        previous: map['previous']?.toString(),
        results: list
            .whereType<Map>()
            .map((item) => fromJson(JsonMap.from(item)))
            .toList(),
      );
    }

    return PagedResult<T>(
      count: 0,
      next: null,
      previous: null,
      results: const [],
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
