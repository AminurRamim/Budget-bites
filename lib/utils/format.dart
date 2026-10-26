import 'package:intl/intl.dart';

String formatMoney(double value, String symbol) {
  final abs = value.abs().toStringAsFixed(2);
  return value < 0 ? '-$symbol$abs' : '$symbol$abs';
}

String formatShortDate(DateTime d) => DateFormat('EEE, MMM d').format(d);
