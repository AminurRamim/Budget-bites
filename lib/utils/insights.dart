import '../models/purchase.dart';

const allCategories = 'All';

/// Aggregate over a filtered set of purchases.
class InsightsSummary {
  const InsightsSummary({
    required this.total,
    required this.average,
    required this.count,
    required this.topMeal,
  });

  final double total;
  final double average;
  final int count;
  final String? topMeal;

  static const empty = InsightsSummary(total: 0, average: 0, count: 0, topMeal: null);

  factory InsightsSummary.from(List<PurchaseRow> rows) {
    if (rows.isEmpty) return empty;
    var total = 0.0;
    final counts = <String, int>{};
    for (final r in rows) {
      total += r.purchase.pricePaid;
      counts.update(r.mealName, (n) => n + 1, ifAbsent: () => 1);
    }
    // Most bought; ties broken alphabetically so the result is deterministic.
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return InsightsSummary(
      total: total,
      average: total / rows.length,
      count: rows.length,
      topMeal: ranked.first.key,
    );
  }
}
