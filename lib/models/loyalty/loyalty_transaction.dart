typedef LoyaltyJson = Map<String, dynamic>;

class LoyaltyTransactionTypeRef {
  final String code;
  final String label;

  const LoyaltyTransactionTypeRef({required this.code, required this.label});

  factory LoyaltyTransactionTypeRef.fromJson(dynamic json) {
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyTransactionTypeRef(
      code: map['code']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
    );
  }
}

class LoyaltyTransactionRelatedRef {
  final String id;
  final String reference;

  const LoyaltyTransactionRelatedRef({
    required this.id,
    required this.reference,
  });

  static LoyaltyTransactionRelatedRef? fromJsonOrNull(dynamic json) {
    if (json == null) return null;
    final map = json is Map ? LoyaltyJson.from(json) : const <String, dynamic>{};
    return LoyaltyTransactionRelatedRef(
      id: map['id']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
    );
  }
}

class LoyaltyTransaction {
  final String id;
  final LoyaltyTransactionTypeRef transactionType;
  final int points;
  final LoyaltyTransactionTypeRef sourceServiceClass;
  final String? description;
  final LoyaltyTransactionRelatedRef? reservation;
  final LoyaltyTransactionRelatedRef? ticket;
  final String sourceKey;
  final String? createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.transactionType,
    required this.points,
    required this.sourceServiceClass,
    this.description,
    this.reservation,
    this.ticket,
    required this.sourceKey,
    this.createdAt,
  });

  bool get isPositive => points >= 0;

  factory LoyaltyTransaction.fromJson(LoyaltyJson json) {
    return LoyaltyTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: LoyaltyTransactionTypeRef.fromJson(json['transaction_type']),
      points: _readInt(json['points']) ?? 0,
      sourceServiceClass: LoyaltyTransactionTypeRef.fromJson(json['source_service_class']),
      description: json['description']?.toString(),
      reservation: LoyaltyTransactionRelatedRef.fromJsonOrNull(json['reservation']),
      ticket: LoyaltyTransactionRelatedRef.fromJsonOrNull(json['ticket']),
      sourceKey: json['source_key']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class LoyaltyTransactionsPage {
  final int count;
  final List<LoyaltyTransaction> results;

  const LoyaltyTransactionsPage({required this.count, required this.results});

  factory LoyaltyTransactionsPage.fromJson(LoyaltyJson json) {
    final rawResults = json['results'];
    final results = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map((item) => LoyaltyTransaction.fromJson(LoyaltyJson.from(item)))
            .toList()
        : <LoyaltyTransaction>[];
    return LoyaltyTransactionsPage(
      count: _readInt(json['count']) ?? results.length,
      results: results,
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
