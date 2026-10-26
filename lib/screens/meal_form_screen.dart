import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../state/budget_controller.dart';
import '../utils/validators.dart';

/// Screen role 2: create / edit form (one screen for both).
class MealFormScreen extends StatefulWidget {
  const MealFormScreen({super.key, this.meal});

  /// Null = create a new meal; otherwise edit this one.
  final Meal? meal;

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.meal?.name ?? '');
  late final _location = TextEditingController(text: widget.meal?.location ?? '');
  late final _price =
      TextEditingController(text: widget.meal?.typicalPrice.toStringAsFixed(2) ?? '');
  late String _category = widget.meal?.category ?? Meal.categories[1];
  bool _saving = false;

  bool get _isEdit => widget.meal != null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final controller = context.read<BudgetController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final meal = Meal(
      id: widget.meal?.id,
      name: _name.text.trim(),
      location: _location.text.trim(),
      category: _category,
      typicalPrice: double.parse(_price.text.trim()),
      createdAt: widget.meal?.createdAt ?? DateTime.now(),
    );

    try {
      await controller.saveMeal(meal);
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(content: Text(_isEdit ? 'Meal updated' : 'Meal added')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the meal. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<BudgetController>().currency;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit meal' : 'Add meal')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Meal name'),
                validator: validateMealName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Where (optional)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: Meal.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Typical price', prefixText: currency),
                validator: validatePrice,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_isEdit ? 'Save changes' : 'Save meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
