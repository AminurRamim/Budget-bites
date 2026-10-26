import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Signature interaction: an animated arc showing how much of the weekly
/// budget is spent, with the remaining amount in the center.
class BudgetDial extends StatelessWidget {
  const BudgetDial({
    super.key,
    required this.spent,
    required this.budget,
    required this.currency,
    this.size = 200,
  });

  final double spent;
  final double budget;
  final String currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ratio = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0).toDouble();
    final remaining = budget - spent;
    final over = remaining < 0;
    final color = over
        ? scheme.error
        : ratio > 0.8
            ? Colors.orange.shade700
            : scheme.primary;

    return Semantics(
      label: 'Weekly budget. Spent ${formatMoney(spent, currency)} of '
          '${formatMoney(budget, currency)}. '
          '${over ? 'Over by' : 'Remaining'} ${formatMoney(remaining.abs(), currency)}.',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DialPainter(
              progress: value,
              color: color,
              trackColor: scheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(over ? 'Over by' : 'Remaining', style: text.labelLarge),
                  Text(
                    formatMoney(remaining.abs(), currency),
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: over ? scheme.error : null,
                    ),
                  ),
                  Text('of ${formatMoney(budget, currency)} this week',
                      style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.progress, required this.color, required this.trackColor});

  final double progress;
  final Color color;
  final Color trackColor;

  static const _start = math.pi * 0.75; // 135 degrees
  static const _sweep = math.pi * 1.5; // 270-degree arc

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, track);
    if (progress > 0) canvas.drawArc(rect, _start, _sweep * progress, false, fill);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}
