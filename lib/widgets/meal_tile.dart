import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../utils/format.dart';

IconData iconForCategory(String category) => switch (category) {
      'Breakfast' => Icons.free_breakfast_outlined,
      'Lunch' => Icons.lunch_dining_outlined,
      'Dinner' => Icons.dinner_dining_outlined,
      _ => Icons.cookie_outlined,
    };

/// Reusable stateless row for a meal in the catalog.
class MealTile extends StatelessWidget {
  const MealTile({
    super.key,
    required this.meal,
    required this.currency,
    required this.onTap,
  });

  final Meal meal;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(iconForCategory(meal.category))),
      title: Text(meal.name),
      subtitle: Text([meal.category, if (meal.location.isNotEmpty) meal.location].join(' · ')),
      trailing: Text(
        formatMoney(meal.typicalPrice, currency),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}
