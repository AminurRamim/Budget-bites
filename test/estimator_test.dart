import 'package:budget_bites/services/estimator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstimatorService (required smart helper)', () {
    test('normal: averages the last three prices', () {
      final e = EstimatorService.estimate(typicalPrice: 8, recentPrices: [7, 8, 10]);
      expect(e.value, 8.33);
      expect(e.basedOn, 3);
      expect(e.reason, contains('last 3'));
    });

    test('no data: falls back to the typical-price baseline', () {
      final e = EstimatorService.estimate(typicalPrice: 9.5, recentPrices: []);
      expect(e.value, 9.5);
      expect(e.isBaseline, isTrue);
      expect(e.reason, contains('not enough history'));
    });

    test('invalid: zero, negative and NaN prices are ignored', () {
      final e = EstimatorService.estimate(typicalPrice: 6, recentPrices: [0, -3, double.nan]);
      expect(e.value, 6);
      expect(e.isBaseline, isTrue);
    });

    test('boundary: a single purchase is used and labeled', () {
      final e = EstimatorService.estimate(typicalPrice: 8, recentPrices: [9]);
      expect(e.value, 9.0);
      expect(e.reason, 'Based on 1 purchase');
    });

    test('outlier counterexample: one expensive order skews the estimate', () {
      final e = EstimatorService.estimate(typicalPrice: 8, recentPrices: [8, 8, 25]);
      expect(e.value, 13.67);
      expect(e.value, greaterThan(EstimatorService.baseline(8)));
    });

    test('only the three most recent prices are used', () {
      final e = EstimatorService.estimate(typicalPrice: 8, recentPrices: [10, 10, 10, 50]);
      expect(e.value, 10.0);
    });
  });
}
