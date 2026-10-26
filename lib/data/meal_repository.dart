import 'package:sqflite/sqflite.dart';

import '../models/meal.dart';
import 'database_helper.dart';

/// CRUD for the meals table.
class MealRepository {
  MealRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  Future<List<Meal>> getAll({String search = ''}) async {
    final db = await _dbHelper.database;
    final q = search.trim();
    final rows = await db.query(
      'meals',
      where: q.isEmpty ? null : 'name LIKE ? OR location LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Meal.fromMap).toList();
  }

  Future<Meal?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('meals', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Meal.fromMap(rows.first);
  }

  Future<int> insert(Meal meal) async {
    final db = await _dbHelper.database;
    return db.insert('meals', meal.toMap()..remove('id'));
  }

  Future<void> update(Meal meal) async {
    final db = await _dbHelper.database;
    await db.update('meals', meal.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [meal.id]);
  }

  /// Purchases are removed by ON DELETE CASCADE.
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> purchaseCount(int mealId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM purchases WHERE meal_id = ?', [mealId]);
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
