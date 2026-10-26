/// Result of the Meal Cost Estimator (the required local smart helper).
class Estimate {
  const Estimate({required this.value, required this.reason, required this.basedOn});

  /// Suggested price, rounded to cents.
  final double value;

  /// Plain-language explanation shown to the user.
  final String reason;

  /// How many past purchases were used (0 = baseline fallback).
  final int basedOn;

  bool get isBaseline => basedOn == 0;
}

/// Rule-based estimator. Not a trained model.
///
/// Rule: average the most recent [maxHistory] valid prices.
/// Fallback (baseline): the meal's typical price.
class EstimatorService {
  static const maxHistory = 3;

  /// [recentPrices] must be ordered newest first.
  static Estimate estimate({
    required double typicalPrice,
    required List<double> recentPrices,
  }) {
    final valid = recentPrices
        .where((p) => p.isFinite && p > 0 && p <= 100)
        .take(maxHistory)
        .toList();

    if (valid.isEmpty) {
      return Estimate(
        value: baseline(typicalPrice),
        reason: 'Using your typical price — not enough history yet',
        basedOn: 0,
      );
    }

    final avg = valid.reduce((a, b) => a + b) / valid.length;
    return Estimate(
      value: _round(avg),
      reason: valid.length == 1
          ? 'Based on 1 purchase'
          : 'Average of your last ${valid.length} purchases',
      basedOn: valid.length,
    );
  }

  /// The comparison baseline: just the typical price.
  static double baseline(double typicalPrice) => _round(typicalPrice);

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
