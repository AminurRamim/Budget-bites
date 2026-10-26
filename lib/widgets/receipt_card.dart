import 'package:flutter/material.dart';

import '../models/purchase.dart';
import '../utils/format.dart';

/// Signature interaction: a transparent receipt shown after logging a purchase.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.mealName,
    required this.purchase,
    required this.remainingBefore,
    required this.remainingAfter,
    required this.currency,
  });

  final String mealName;
  final Purchase purchase;
  final double remainingBefore;
  final double remainingAfter;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.receipt_long, size: 40, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text('Spending receipt', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const Divider(height: 24),
        _line('Meal', mealName),
        _line('Paid', formatMoney(purchase.pricePaid, currency)),
        _line('Date', formatShortDate(purchase.purchasedAt)),
        if (purchase.note.isNotEmpty) _line('Note', purchase.note),
        const Divider(height: 24),
        _line('Left before', formatMoney(remainingBefore, currency)),
        _line('Left after', formatMoney(remainingAfter, currency)),
      ],
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label),
            const SizedBox(width: 16),
            Expanded(child: Text(value, textAlign: TextAlign.end)),
          ],
        ),
      );
}
