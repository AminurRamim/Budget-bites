import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../state/budget_controller.dart';
import '../utils/format.dart';
import '../widgets/confirm_dialogs.dart';

/// Screen role 5: settings (SharedPreferences).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Slider value while dragging; saved only when the drag ends.
  double? _draftBudget;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final text = Theme.of(context).textTheme;
    final budget = (_draftBudget ?? c.weeklyBudget).clamp(20.0, 200.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Weekly food budget', style: text.titleMedium),
          Text(formatMoney(budget, c.currency), style: text.headlineSmall),
          Slider(
            value: budget,
            min: 20,
            max: 200,
            divisions: 36,
            label: formatMoney(budget, c.currency),
            semanticFormatterCallback: (v) => 'Weekly budget ${v.round()}',
            onChanged: (v) => setState(() => _draftBudget = v),
            onChangeEnd: (v) async {
              await c.setWeeklyBudget(v);
              if (mounted) setState(() => _draftBudget = null);
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Week starts on'),
            trailing: DropdownButton<int>(
              value: c.weekStartDay,
              items: const [
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
              ],
              onChanged: (v) {
                if (v != null) c.setWeekStartDay(v);
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Currency symbol'),
            trailing: DropdownButton<String>(
              value: c.currency,
              items: SettingsService.currencies
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) c.setCurrency(v);
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode'),
            value: c.darkMode,
            onChanged: c.setDarkMode,
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset settings'),
            subtitle: const Text(
                'Restores budget, week start, currency, and theme. Meals and purchases are kept.'),
            onTap: () async {
              final ok = await confirmAction(
                context,
                title: 'Reset settings?',
                message: 'Your meals and purchases will not be deleted.',
                confirmLabel: 'Reset',
              );
              if (ok) await c.resetSettings();
            },
          ),
          const SizedBox(height: 16),
          Text(
            'All data stays on this device. Budget Bites uses no cloud services.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
