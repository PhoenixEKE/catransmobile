class CatalogFare {
  final String id;
  final String amount;
  final String currency;
  final String displayAmount;

  const CatalogFare({
    required this.id,
    required this.amount,
    required this.currency,
    required this.displayAmount,
  });

  factory CatalogFare.fromJson(Map<String, dynamic> json) {
    return CatalogFare(
      id: json['id'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      displayAmount: json['display_amount'] as String,
    );
  }

  double? get amountAsDouble => double.tryParse(amount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'display_amount': displayAmount,
      };
}
