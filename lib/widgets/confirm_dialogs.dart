import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../state/budget_controller.dart';

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}

/// Parent-delete policy: tell the user how many purchases go with the meal.
Future<bool> confirmMealDelete(BuildContext context, Meal meal) async {
  final count = await context.read<BudgetController>().purchaseCountFor(meal.id!);
  if (!context.mounted) return false;
  return confirmAction(
    context,
    title: 'Delete ${meal.name}?',
    message: count == 0
        ? 'This meal has no purchases.'
        : 'This also deletes $count purchase${count == 1 ? '' : 's'} linked to it. '
            'This cannot be undone.',
  );
}
