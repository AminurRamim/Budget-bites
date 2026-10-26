import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/budget_controller.dart';
import '../utils/format.dart';
import '../widgets/budget_dial.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/meal_tile.dart';
import 'meal_detail_screen.dart';
import 'meal_form_screen.dart';

/// Screen role 1: catalog / dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<BudgetController>().search);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openDetail(int mealId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealDetailScreen(mealId: mealId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Desk')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MealFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: c.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header(c, scheme)),
                  if (c.meals.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          c.search.isEmpty
                              ? 'No meals yet. Tap "Add meal" to save one you buy often.'
                              : 'No meals match "${c.search}".',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 88),
                      sliver: SliverList.builder(
                        itemCount: c.meals.length,
                        itemBuilder: (context, i) {
                          final meal = c.meals[i];
                          return Dismissible(
                            key: ValueKey('meal-${meal.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: scheme.errorContainer,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                            ),
                            confirmDismiss: (_) => confirmMealDelete(context, meal),
                            onDismissed: (_) async {
                              final messenger = ScaffoldMessenger.of(context);
                              await c.deleteMeal(meal.id!);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Deleted ${meal.name}')),
                              );
                            },
                            child: MealTile(
                              meal: meal,
                              currency: c.currency,
                              onTap: () => _openDetail(meal.id!),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _header(BudgetController c, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.error != null)
            Card(
              color: scheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(c.error!),
              ),
            ),
          Center(
            child: BudgetDial(spent: c.spent, budget: c.weeklyBudget, currency: c.currency),
          ),
          const SizedBox(height: 8),
          Text(
            'Spent ${formatMoney(c.spent, c.currency)} since ${formatShortDate(c.weekStart)}',
            textAlign: TextAlign.center,
          ),
          for (final row in c.unfinished)
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions),
                title: Text('Unfinished purchase: ${row.mealName}'),
                subtitle: Text('Started ${formatShortDate(row.purchase.purchasedAt)}'),
                trailing: TextButton(
                  onPressed: () => _openDetail(row.purchase.mealId),
                  child: const Text('Resume'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search meals or places',
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        c.setSearch('');
                      },
                    ),
            ),
            onChanged: c.setSearch,
          ),
        ],
      ),
    );
  }
}
