import '../models/purchase.dart';
import 'database_helper.dart';

/// CRUD and queries for the purchases table.
class PurchaseRepository {
  PurchaseRepository(this._dbHelper);
  final DatabaseHelper _dbHelper;

  static const _joinSelect = '''
    SELECT p.*, m.name AS meal_name, m.category AS meal_category
    FROM purchases p
    JOIN meals m ON m.id = p.meal_id
  ''';

  Future<int> insert(Purchase p) async {
    final db = await _dbHelper.database;
    return db.insert('purchases', p.toMap()..remove('id'));
  }

  Future<void> update(Purchase p) async {
    final db = await _dbHelper.database;
    await db.update('purchases', p.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  /// Logged purchases for one meal, newest first.
  Future<List<Purchase>> loggedForMeal(int mealId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'purchases',
      where: 'meal_id = ? AND status = ?',
      whereArgs: [mealId, PurchaseStatus.logged.dbValue],
      orderBy: 'purchased_at DESC',
    );
    return rows.map(Purchase.fromMap).toList();
  }

  Future<Purchase?> inProgressForMeal(int mealId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'purchases',
      where: 'meal_id = ? AND status = ?',
      whereArgs: [mealId, PurchaseStatus.inProgress.dbValue],
      orderBy: 'purchased_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Purchase.fromMap(rows.first);
  }

  /// Unfinished purchases across all meals (restored after a restart).
  Future<List<PurchaseRow>> inProgressAll() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_joinSelect WHERE p.status = ? ORDER BY p.purchased_at DESC',
      [PurchaseStatus.inProgress.dbValue],
    );
    return rows.map(PurchaseRow.fromMap).toList();
  }

  /// Sum of logged purchases in [start, end).
  Future<double> totalBetween(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(price_paid), 0) AS total FROM purchases '
      'WHERE status = ? AND purchased_at >= ? AND purchased_at < ?',
      [PurchaseStatus.logged.dbValue, start.toIso8601String(), end.toIso8601String()],
    );
    return (rows.first['total'] as num).toDouble();
  }

  /// Filtered logged purchases for Insights.
  Future<List<PurchaseRow>> logged({
    DateTime? start,
    DateTime? end,
    String? category,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>['p.status = ?'];
    final args = <Object>[PurchaseStatus.logged.dbValue];
    if (start != null) {
      where.add('p.purchased_at >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('p.purchased_at < ?');
      args.add(end.toIso8601String());
    }
    if (category != null) {
      where.add('m.category = ?');
      args.add(category);
    }
    final rows = await db.rawQuery(
      '$_joinSelect WHERE ${where.join(' AND ')} ORDER BY p.purchased_at DESC',
      args,
    );
    return rows.map(PurchaseRow.fromMap).toList();
  }
}
