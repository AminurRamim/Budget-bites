/// Workflow state of a purchase: started (in progress) or finished (logged).
enum PurchaseStatus {
  inProgress('in_progress'),
  logged('logged');

  const PurchaseStatus(this.dbValue);
  final String dbValue;

  static PurchaseStatus fromDb(String value) => PurchaseStatus.values
      .firstWhere((s) => s.dbValue == value, orElse: () => PurchaseStatus.logged);
}

/// One purchase of a meal (activity/history SQLite record).
class Purchase {
  final int? id;
  final int mealId;
  final double pricePaid;
  final DateTime purchasedAt;
  final String note;
  final PurchaseStatus status;

  const Purchase({
    this.id,
    required this.mealId,
    required this.pricePaid,
    required this.purchasedAt,
    this.note = '',
    this.status = PurchaseStatus.logged,
  });

  Purchase copyWith({
    int? id,
    double? pricePaid,
    DateTime? purchasedAt,
    String? note,
    PurchaseStatus? status,
  }) {
    return Purchase(
      id: id ?? this.id,
      mealId: mealId,
      pricePaid: pricePaid ?? this.pricePaid,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'meal_id': mealId,
        'price_paid': pricePaid,
        'purchased_at': purchasedAt.toIso8601String(),
        'note': note,
        'status': status.dbValue,
      };

  factory Purchase.fromMap(Map<String, Object?> m) => Purchase(
        id: m['id'] as int?,
        mealId: m['meal_id'] as int,
        pricePaid: (m['price_paid'] as num).toDouble(),
        purchasedAt: DateTime.parse(m['purchased_at'] as String),
        note: (m['note'] as String?) ?? '',
        status: PurchaseStatus.fromDb(m['status'] as String),
      );
}

/// A purchase joined with its meal's name and category (for lists and insights).
class PurchaseRow {
  final Purchase purchase;
  final String mealName;
  final String mealCategory;

  const PurchaseRow({
    required this.purchase,
    required this.mealName,
    required this.mealCategory,
  });

  factory PurchaseRow.fromMap(Map<String, Object?> m) => PurchaseRow(
        purchase: Purchase.fromMap(m),
        mealName: m['meal_name'] as String,
        mealCategory: m['meal_category'] as String,
      );
}
