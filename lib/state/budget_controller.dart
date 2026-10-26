import 'package:flutter/foundation.dart';

import '../data/meal_repository.dart';
import '../data/purchase_repository.dart';
import '../models/meal.dart';
import '../models/purchase.dart';
import '../services/settings_service.dart';
import '../utils/week.dart';

/// Shared app state: meal list, weekly spending, unfinished purchases, settings.
///
/// Screens read from it with Provider and call its methods; it talks to the
/// repositories and SettingsService, then notifies listeners so the budget
/// dial and lists rebuild.
class BudgetController extends ChangeNotifier {
  BudgetController({
    required MealRepository meals,
    required PurchaseRepository purchases,
    required SettingsService settings,
  })  : _meals = meals,
        _purchases = purchases,
        _settings = settings;

  final MealRepository _meals;
  final PurchaseRepository _purchases;
  final SettingsService _settings;

  List<Meal> _mealList = [];
  List<PurchaseRow> _unfinished = [];
  double _spent = 0;
  bool _loading = true;
  String? _error;
  String _search = '';

  List<Meal> get meals => List.unmodifiable(_mealList);
  List<PurchaseRow> get unfinished => List.unmodifiable(_unfinished);
  double get spent => _spent;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;

  double get weeklyBudget => _settings.weeklyBudget;
  int get weekStartDay => _settings.weekStartDay;
  String get currency => _settings.currency;
  bool get darkMode => _settings.darkMode;
  String get lastCategoryFilter => _settings.lastCategory;

  double get remaining => weeklyBudget - _spent;
  DateTime get weekStart => weekStartFor(DateTime.now(), weekStartDay);
  DateTime get weekEnd => weekEndFor(weekStart);

  Future<void> refresh() async {
    try {
      _mealList = await _meals.getAll(search: _search);
      _spent = await _purchases.totalBetween(weekStart, weekEnd);
      _unfinished = await _purchases.inProgressAll();
      _error = null;
    } catch (e) {
      _error = 'Could not load your data. Pull down to try again.';
      debugPrint('BudgetController.refresh failed: $e');
    }
    _loading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  // ---- Meals ----
  Future<Meal?> mealById(int id) => _meals.getById(id);
  Future<int> purchaseCountFor(int mealId) => _meals.purchaseCount(mealId);

  Future<void> saveMeal(Meal meal) async {
    if (meal.id == null) {
      await _meals.insert(meal);
    } else {
      await _meals.update(meal);
    }
    await refresh();
  }

  Future<void> deleteMeal(int id) async {
    await _meals.delete(id);
    await refresh();
  }

  // ---- Purchases (start -> progress -> finish / cancel) ----
  Future<List<Purchase>> historyFor(int mealId) => _purchases.loggedForMeal(mealId);
  Future<Purchase?> inProgressFor(int mealId) => _purchases.inProgressForMeal(mealId);

  /// Start: creates an in-progress row (price 0 = not entered yet).
  Future<Purchase> startPurchase(int mealId) async {
    final draft = Purchase(
      mealId: mealId,
      pricePaid: 0,
      purchasedAt: DateTime.now(),
      status: PurchaseStatus.inProgress,
    );
    final id = await _purchases.insert(draft);
    await refresh();
    return draft.copyWith(id: id);
  }

  /// Progress: saves the draft so it survives an app restart. No rebuild needed.
  Future<void> saveDraft(Purchase draft) async {
    try {
      await _purchases.update(draft);
    } catch (e) {
      debugPrint('saveDraft failed: $e');
    }
  }

  /// Finish: marks the purchase as logged and updates the weekly total.
  Future<void> finishPurchase(Purchase purchase) async {
    await _purchases.update(purchase.copyWith(status: PurchaseStatus.logged));
    await refresh();
  }

  /// Reset: discards an unfinished purchase.
  Future<void> cancelPurchase(Purchase purchase) async {
    if (purchase.id != null) await _purchases.delete(purchase.id!);
    await refresh();
  }

  Future<void> updatePurchase(Purchase purchase) async {
    await _purchases.update(purchase);
    await refresh();
  }

  Future<void> deletePurchase(int id) async {
    await _purchases.delete(id);
    await refresh();
  }

  Future<List<PurchaseRow>> loggedPurchases({
    DateTime? start,
    DateTime? end,
    String? category,
  }) =>
      _purchases.logged(start: start, end: end, category: category);

  // ---- Settings ----
  Future<void> setWeeklyBudget(double v) async {
    await _settings.setWeeklyBudget(v);
    notifyListeners();
  }

  Future<void> setWeekStartDay(int v) async {
    await _settings.setWeekStartDay(v);
    await refresh(); // the week window moved, so the total changes
  }

  Future<void> setCurrency(String v) async {
    await _settings.setCurrency(v);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    await _settings.setDarkMode(v);
    notifyListeners();
  }

  Future<void> setLastCategory(String v) => _settings.setLastCategory(v);

  Future<void> resetSettings() async {
    await _settings.reset();
    await refresh();
  }
}
