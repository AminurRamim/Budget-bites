import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database_helper.dart';
import 'data/meal_repository.dart';
import 'data/purchase_repository.dart';
import 'screens/root_shell.dart';
import 'services/settings_service.dart';
import 'state/budget_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsService.load();
  final db = DatabaseHelper.instance;
  final controller = BudgetController(
    meals: MealRepository(db),
    purchases: PurchaseRepository(db),
    settings: settings,
  );
  await controller.refresh();
  runApp(ChangeNotifierProvider.value(value: controller, child: const BudgetBitesApp()));
}

class BudgetBitesApp extends StatefulWidget {
  const BudgetBitesApp({super.key});

  @override
  State<BudgetBitesApp> createState() => _BudgetBitesAppState();
}

class _BudgetBitesAppState extends State<BudgetBitesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DatabaseHelper.instance.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app may cross into a new week: recompute totals.
    if (state == AppLifecycleState.resumed) {
      context.read<BudgetController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.select<BudgetController, bool>((c) => c.darkMode);
    return MaterialApp(
      title: 'Budget Bites',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: const RootShell(),
    );
  }
}

ThemeData _theme(Brightness brightness) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB5400F),
        brightness: brightness,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
