import 'package:shared_preferences/shared_preferences.dart';

/// Key-value settings stored with SharedPreferences.
class SettingsService {
  SettingsService(this._prefs);
  final SharedPreferences _prefs;

  static Future<SettingsService> load() async =>
      SettingsService(await SharedPreferences.getInstance());

  static const currencies = ['\$', '€', '£', '৳', '¥'];
  static const defaultBudget = 75.0;

  static const _kBudget = 'weekly_budget';
  static const _kWeekStart = 'week_start_day';
  static const _kCurrency = 'currency_symbol';
  static const _kDark = 'dark_mode';
  static const _kLastCategory = 'last_category_filter';

  double get weeklyBudget => _prefs.getDouble(_kBudget) ?? defaultBudget;
  int get weekStartDay => _prefs.getInt(_kWeekStart) ?? DateTime.monday;
  String get currency {
    final v = _prefs.getString(_kCurrency);
    return currencies.contains(v) ? v! : currencies.first;
  }
  bool get darkMode => _prefs.getBool(_kDark) ?? false;
  String get lastCategory => _prefs.getString(_kLastCategory) ?? 'All';

  Future<void> setWeeklyBudget(double v) async => _prefs.setDouble(_kBudget, v);
  Future<void> setWeekStartDay(int v) async => _prefs.setInt(_kWeekStart, v);
  Future<void> setCurrency(String v) async => _prefs.setString(_kCurrency, v);
  Future<void> setDarkMode(bool v) async => _prefs.setBool(_kDark, v);
  Future<void> setLastCategory(String v) async => _prefs.setString(_kLastCategory, v);

  Future<void> reset() async {
    for (final k in [_kBudget, _kWeekStart, _kCurrency, _kDark, _kLastCategory]) {
      await _prefs.remove(k);
    }
  }
}
