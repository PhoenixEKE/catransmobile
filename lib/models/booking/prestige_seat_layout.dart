/// Numbering rules for the fixed 2 + 2 Prestige coach layout.
class PrestigeSeatLayout {
  static const hiddenSeatNumbers = <int>{10, 29, 30, 31, 32};

  /// Returns the four seat numbers from left window to right window.
  ///
  /// A `null` value represents a deliberately empty location. Seat 58 is the
  /// only exception to the regular numbering and is placed at the end of the
  /// aisle, on its own final row.
  static List<List<int?>> rowsFor(Iterable<int> backendSeatNumbers) {
    final numbers = backendSeatNumbers
        .where((number) => number >= 2 && number <= 58)
        .toSet();
    if (numbers.isEmpty) return const [];

    final regularNumbers = numbers.where((number) => number <= 57).toList();
    final rows = <List<int?>>[];

    if (regularNumbers.isNotEmpty) {
      final firstRow = regularNumbers.map(rowForSeat).reduce(_min);
      final lastRow = regularNumbers.map(rowForSeat).reduce(_max);

      for (var row = firstRow; row <= lastRow; row++) {
        final aisleLeft = 2 + ((row - 1) * 4);
        final orderedNumbers = <int>[
          aisleLeft + 1,
          aisleLeft,
          aisleLeft + 2,
          aisleLeft + 3,
        ];
        rows.add([
          for (final number in orderedNumbers)
            numbers.contains(number) && !hiddenSeatNumbers.contains(number)
                ? number
                : null,
        ]);
      }
    }

    if (numbers.contains(58)) {
      // The middle nulls describe the aisle; 58 sits at its very end.
      rows.add(const [null, null, 58, null]);
    }

    return rows;
  }

  static int rowForSeat(int seatNumber) => ((seatNumber - 2) ~/ 4) + 1;

  static int _min(int a, int b) => a < b ? a : b;
  static int _max(int a, int b) => a > b ? a : b;
}
