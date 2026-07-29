class StationBoardingSummaryResponse {
  final String departureId;
  final StationBoardingSummaryCounts summary;

  const StationBoardingSummaryResponse({
    required this.departureId,
    required this.summary,
  });

  factory StationBoardingSummaryResponse.fromJson(Map<String, dynamic> json) {
    return StationBoardingSummaryResponse(
      departureId: json['departure_id']?.toString() ?? '',
      summary:
          StationBoardingSummaryCounts.fromJson(_readObject(json['summary'])),
    );
  }
}

class StationBoardingSummaryCounts {
  final int totalTickets;
  final int issued;
  final int boarded;
  final int cancelled;
  final int remainingToBoard;

  const StationBoardingSummaryCounts({
    required this.totalTickets,
    required this.issued,
    required this.boarded,
    required this.cancelled,
    required this.remainingToBoard,
  });

  double get boardingRate {
    if (totalTickets <= 0) return 0;
    return boarded / totalTickets;
  }

  factory StationBoardingSummaryCounts.fromJson(Map<String, dynamic> json) {
    return StationBoardingSummaryCounts(
      totalTickets: _readInt(json['total_tickets']),
      issued: _readInt(json['issued']),
      boarded: _readInt(json['boarded']),
      cancelled: _readInt(json['cancelled']),
      remainingToBoard: _readInt(json['remaining_to_board']),
    );
  }
}

Map<String, dynamic> _readObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

int _readInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
