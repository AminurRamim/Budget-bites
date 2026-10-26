import 'package:budget_bites/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePrice', () {
    test('accepts a normal price', () => expect(validatePrice('8.50'), isNull));
    test('rejects blank', () => expect(validatePrice('  '), isNotNull));
    test('rejects text', () => expect(validatePrice('abc'), isNotNull));
    test('rejects zero and negative', () {
      expect(validatePrice('0'), isNotNull);
      expect(validatePrice('-2'), isNotNull);
    });
    test('rejects NaN and over 100', () {
      expect(validatePrice('NaN'), isNotNull);
      expect(validatePrice('100.01'), isNotNull);
    });
    test('accepts the 100 boundary', () => expect(validatePrice('100'), isNull));
  });

  group('validateMealName', () {
    test('rejects blank', () => expect(validateMealName(''), isNotNull));
    test('rejects over 40 characters', () => expect(validateMealName('a' * 41), isNotNull));
    test('accepts a normal name', () => expect(validateMealName('Pad thai'), isNull));
  });
}
