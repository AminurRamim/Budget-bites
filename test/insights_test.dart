import 'package:budget_bites/models/purchase.dart';
import 'package:budget_bites/utils/insights.dart';
import 'package:budget_bites/utils/week.dart';
import 'package:flutter_test/flutter_test.dart';

PurchaseRow row(String meal, double price) => PurchaseRow(
      purchase: Purchase(mealId: 1, pricePaid: price, purchasedAt: DateTime(2026, 10, 26)),
      mealName: meal,
      mealCategory: 'Lunch',
    );

void main() {
  group('InsightsSummary', () {
    test('empty list gives zeros', () {
      final s = InsightsSummary.from([]);
      expect(s.count, 0);
      expect(s.total, 0);
      expect(s.topMeal, isNull);
    });

    test('computes total, average and most bought', () {
      final s = InsightsSummary.from([row('Bowl', 10), row('Bowl', 8), row('Bagel', 6)]);
      expect(s.total, 24);
      expect(s.average, 8);
      expect(s.count, 3);
      expect(s.topMeal, 'Bowl');
    });

    test('ties are broken alphabetically', () {
      final s = InsightsSummary.from([row('Pad thai', 11), row('Bagel', 5)]);
      expect(s.topMeal, 'Bagel');
    });
  });

  group('weekStartFor', () {
    test('Monday start from a Wednesday', () {
      expect(weekStartFor(DateTime(2026, 10, 28, 15), DateTime.monday), DateTime(2026, 10, 26));
    });
    test('Sunday start', () {
      expect(weekStartFor(DateTime(2026, 10, 28, 15), DateTime.sunday), DateTime(2026, 10, 25));
    });
    test('the start day itself', () {
      expect(weekStartFor(DateTime(2026, 10, 26, 9), DateTime.monday), DateTime(2026, 10, 26));
    });
  });
}
