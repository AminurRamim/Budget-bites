import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../models/purchase.dart';
import '../state/budget_controller.dart';
import '../utils/format.dart';
import '../utils/insights.dart';
import '../widgets/meal_tile.dart';

enum RangePreset { thisWeek, last30Days, allTime }

/// Screen role 4: history / insights (filter + aggregate).
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static final _categoryOptions = [allCategories, ...Meal.categories];

  RangePreset _range = RangePreset.thisWeek;
  late String _category;
  List<PurchaseRow> _rows = [];
  InsightsSummary _summary = InsightsSummary.empty;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = context.read<BudgetController>().lastCategoryFilter;
    _category = _categoryOptions.contains(saved) ? saved : allCategories;
    _load();
  }

  Future<void> _load() async {
    final c = context.read<BudgetController>();
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;
    switch (_range) {
      case RangePreset.thisWeek:
        start = c.weekStart;
        end = c.weekEnd;
      case RangePreset.last30Days:
        start = DateTime(now.year, now.month, now.day - 29);
        end = DateTime(now.year, now.month, now.day + 1);
      case RangePreset.allTime:
        break;
    }
    try {
      final rows = await c.loggedPurchases(
        start: start,
        end: end,
        category: _category == allCategories ? null : _category,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _summary = InsightsSummary.from(rows);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load insights.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Insights')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<RangePreset>(
                    segments: const [
                      ButtonSegment(value: RangePreset.thisWeek, label: Text('This week')),
                      ButtonSegment(value: RangePreset.last30Days, label: Text('30 days')),
                      ButtonSegment(value: RangePreset.allTime, label: Text('All time')),
                    ],
                    selected: {_range},
                    onSelectionChanged: (s) {
                      setState(() {
                        _range = s.first;
                        _loading = true;
                      });
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categoryOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _category = v;
                        _loading = true;
                      });
                      c.setLastCategory(v);
                      _load();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  _StatsGrid(summary: _summary, currency: c.currency),
                  const SizedBox(height: 16),
                  Text('Purchases (${_summary.count})', style: text.titleMedium),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_rows.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No purchases match these filters.', textAlign: TextAlign.center),
              ),
            )
          else
            SliverList.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final r = _rows[i];
                return ListTile(
                  leading: Icon(iconForCategory(r.mealCategory)),
                  title: Text(r.mealName),
                  subtitle: Text(formatShortDate(r.purchase.purchasedAt)),
                  trailing: Text(formatMoney(r.purchase.pricePaid, c.currency)),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary, required this.currency});
  final InsightsSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Two columns on phones, four on wide screens / landscape.
      final columns = constraints.maxWidth >= 600 ? 4 : 2;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatCard(width: width, label: 'Total spent', value: formatMoney(summary.total, currency)),
          _StatCard(width: width, label: 'Average', value: formatMoney(summary.average, currency)),
          _StatCard(width: width, label: 'Purchases', value: '${summary.count}'),
          _StatCard(width: width, label: 'Most bought', value: summary.topMeal ?? '—'),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.width, required this.label, required this.value});
  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelMedium),
              const SizedBox(height: 4),
              Text(value,
                  style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
