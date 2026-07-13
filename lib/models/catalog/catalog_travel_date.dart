class CatalogTravelDate {
  final DateTime date;
  final int departuresCount;

  const CatalogTravelDate({
    required this.date,
    required this.departuresCount,
  });

  factory CatalogTravelDate.fromJson(Map<String, dynamic> json) {
    return CatalogTravelDate(
      date: DateTime.parse(json['date'] as String),
      departuresCount: json['departures_count'] as int,
    );
  }

  String get apiDate {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> toJson() => {
        'date': apiDate,
        'departures_count': departuresCount,
      };
}
