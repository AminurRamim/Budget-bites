import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../models/purchase.dart';
import '../services/estimator_service.dart';
import '../state/budget_controller.dart';
import '../utils/format.dart';
import '../utils/validators.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/meal_tile.dart';
import '../widgets/receipt_card.dart';
import 'meal_form_screen.dart';

enum _FlowStep { idle, inProgress }

/// Screen role 3: detail + activity (start -> progress -> finish / cancel).
class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key, required this.mealId});
  final int mealId;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _flowFormKey = GlobalKey<FormState>();
  Timer? _draftTimer;

  Meal? _meal;
  List<Purchase> _history = [];
  Estimate? _estimate;
  bool _suggestionHidden = false;
  Purchase? _active;
  _FlowStep _step = _FlowStep.idle;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = context.read<BudgetController>();
    try {
      final meal = await c.mealById(widget.mealId);
      if (meal == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'This meal no longer exists.';
        });
        return;
      }
      final history = await c.historyFor(widget.mealId);
      final active = await c.inProgressFor(widget.mealId);
      if (!mounted) return;
      setState(() {
        _meal = meal;
        _history = history;
        _estimate = EstimatorService.estimate(
          typicalPrice: meal.typicalPrice,
          recentPrices: history.map((p) => p.pricePaid).toList(),
        );
        _active = active;
        _step = active == null ? _FlowStep.idle : _FlowStep.inProgress;
        // Restore an unfinished draft (e.g. after an app restart).
        if (active != null && _priceCtrl.text.isEmpty && _noteCtrl.text.isEmpty) {
          if (active.pricePaid > 0) _priceCtrl.text = active.pricePaid.toStringAsFixed(2);
          _noteCtrl.text = active.note;
        }
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load this meal.';
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Workflow ----

  Future<void> _start({bool applyEstimate = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final c = context.read<BudgetController>();
    try {
      final draft = await c.startPurchase(widget.mealId);
      if (!mounted) return;
      setState(() {
        _active = draft;
        _step = _FlowStep.inProgress;
        _priceCtrl.clear();
        _noteCtrl.clear();
        if (applyEstimate && _estimate != null) {
          _priceCtrl.text = _estimate!.value.toStringAsFixed(2);
        }
      });
      if (applyEstimate) _scheduleDraftSave();
    } catch (_) {
      _showSnack('Could not start the purchase.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Apply" on the suggestion card: the user explicitly accepts the estimate.
  void _applySuggestion() {
    if (_step == _FlowStep.idle) {
      _start(applyEstimate: true);
      return;
    }
    setState(() => _priceCtrl.text = _estimate!.value.toStringAsFixed(2));
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), () {
      final active = _active;
      if (active == null || !mounted) return;
      final typed = double.tryParse(_priceCtrl.text.trim());
      final price = (typed != null && typed.isFinite && typed >= 0 && typed <= 100) ? typed : 0.0;
      context
          .read<BudgetController>()
          .saveDraft(active.copyWith(pricePaid: price, note: _noteCtrl.text.trim()));
    });
  }

  Future<void> _finish() async {
    final active = _active;
    final meal = _meal;
    if (active == null || meal == null || _busy) return;
    if (!_flowFormKey.currentState!.validate()) return;
    _draftTimer?.cancel();
    setState(() => _busy = true);

    final c = context.read<BudgetController>();
    final before = c.remaining;
    final logged = active.copyWith(
      pricePaid: double.parse(_priceCtrl.text.trim()),
      note: _noteCtrl.text.trim(),
      purchasedAt: DateTime.now(),
      status: PurchaseStatus.logged,
    );

    try {
      await c.finishPurchase(logged);
      if (!mounted) return;
      setState(() {
        _active = null;
        _step = _FlowStep.idle;
        _priceCtrl.clear();
        _noteCtrl.clear();
        _suggestionHidden = false;
      });
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: ReceiptCard(
            mealName: meal.name,
            purchase: logged,
            remainingBefore: before,
            remainingAfter: c.remaining,
            currency: c.currency,
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
          ],
        ),
      );
      await _load();
    } catch (_) {
      _showSnack('Could not log the purchase. Your draft is kept.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final active = _active;
    if (active == null) return;
    _draftTimer?.cancel();
    final c = context.read<BudgetController>();
    try {
      await c.cancelPurchase(active);
      if (!mounted) return;
      setState(() {
        _active = null;
        _step = _FlowStep.idle;
        _priceCtrl.clear();
        _noteCtrl.clear();
      });
    } catch (_) {
      _showSnack('Could not cancel the purchase.');
    }
  }

  // ---- History CRUD ----

  Future<void> _editPurchase(Purchase p) async {
    final c = context.read<BudgetController>();
    final newPrice = await showDialog<double>(
      context: context,
      builder: (_) => _EditPriceDialog(initial: p.pricePaid, currency: c.currency),
    );
    if (newPrice == null) return;
    try {
      await c.updatePurchase(p.copyWith(pricePaid: newPrice));
      await _load();
    } catch (_) {
      _showSnack('Could not update the purchase.');
    }
  }

  Future<void> _deletePurchase(Purchase p) async {
    final c = context.read<BudgetController>();
    final ok = await confirmAction(
      context,
      title: 'Delete this purchase?',
      message: 'Removes ${formatMoney(p.pricePaid, c.currency)} from '
          '${formatShortDate(p.purchasedAt)}. Your weekly total will update.',
    );
    if (!ok) return;
    try {
      await c.deletePurchase(p.id!);
      await _load();
    } catch (_) {
      _showSnack('Could not delete the purchase.');
    }
  }

  Future<void> _editMeal() async {
    final meal = _meal;
    if (meal == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MealFormScreen(meal: meal)),
    );
    await _load();
  }

  Future<void> _deleteMeal() async {
    final meal = _meal;
    if (meal == null) return;
    final c = context.read<BudgetController>();
    final navigator = Navigator.of(context);
    final ok = await confirmMealDelete(context, meal);
    if (!ok) return;
    _draftTimer?.cancel();
    await c.deleteMeal(meal.id!);
    navigator.pop();
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final meal = _meal;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || meal == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center),
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(meal, c),
          const SizedBox(height: 12),
          if (_estimate != null && !_suggestionHidden) _suggestionCard(c),
          const SizedBox(height: 12),
          if (_step == _FlowStep.idle)
            FilledButton.icon(
              onPressed: _busy ? null : () => _start(),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Buy this meal'),
            )
          else
            _flowCard(c),
          const SizedBox(height: 24),
          Text('Purchase history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            const Text('No purchases yet. Log one to start building history.')
          else
            ..._history.map(
              (p) => Card(
                child: ListTile(
                  title: Text(formatMoney(p.pricePaid, c.currency)),
                  subtitle: Text(
                    [formatShortDate(p.purchasedAt), if (p.note.isNotEmpty) p.note].join(' · '),
                  ),
                  onLongPress: () => _editPurchase(p),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Purchase actions',
                    onSelected: (v) => v == 'edit' ? _editPurchase(p) : _deletePurchase(p),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit price')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(meal?.name ?? 'Meal'),
        actions: [
          if (meal != null)
            IconButton(
              tooltip: 'Edit meal',
              onPressed: _editMeal,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (meal != null)
            IconButton(
              tooltip: 'Delete meal',
              onPressed: _deleteMeal,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _infoCard(Meal meal, BudgetController c) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(iconForCategory(meal.category)),
              const SizedBox(width: 8),
              Text(meal.category, style: text.titleSmall),
            ]),
            if (meal.location.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(meal.location)),
            const SizedBox(height: 8),
            Text('Typical price: ${formatMoney(meal.typicalPrice, c.currency)}'),
            Text('Left this week: ${formatMoney(c.remaining, c.currency)}'),
          ],
        ),
      ),
    );
  }

  Widget _suggestionCard(BudgetController c) {
    final e = _estimate!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fits = e.value <= c.remaining;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(child: Text('Suggested estimate (not guaranteed)', style: text.titleSmall)),
            ]),
            const SizedBox(height: 8),
            Text(formatMoney(e.value, c.currency), style: text.headlineSmall),
            Text(e.reason),
            const SizedBox(height: 4),
            Text(
              fits ? 'Fits your remaining budget.' : 'This would put you over budget this week.',
              style: TextStyle(color: fits ? null : scheme.error),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _suggestionHidden = true),
                  child: const Text('Not now'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _applySuggestion,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _flowCard(BudgetController c) {
    final typed = double.tryParse(_priceCtrl.text.trim());
    final preview = (typed != null && typed.isFinite && typed > 0) ? c.remaining - typed : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _flowFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Chip(
                  avatar: Icon(Icons.timelapse, size: 18),
                  label: Text('Purchase in progress'),
                ),
                const Spacer(),
                Text('Enter what you paid', style: Theme.of(context).textTheme.labelMedium),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price paid', prefixText: c.currency),
                validator: validatePrice,
                onChanged: (_) {
                  setState(() {});
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                validator: validateNote,
                onChanged: (_) => _scheduleDraftSave(),
              ),
              if (preview != null)
                Text(
                  preview >= 0
                      ? 'After this: ${formatMoney(preview, c.currency)} left this week'
                      : 'After this: over budget by ${formatMoney(-preview, c.currency)}',
                ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _cancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _finish,
                    child: const Text('Finish & log'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPriceDialog extends StatefulWidget {
  const _EditPriceDialog({required this.initial, required this.currency});
  final double initial;
  final String currency;

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late final _ctrl = TextEditingController(text: widget.initial.toStringAsFixed(2));
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit price'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Price paid', prefixText: widget.currency),
          validator: validatePrice,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_key.currentState!.validate()) {
              Navigator.of(context).pop(double.parse(_ctrl.text.trim()));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
