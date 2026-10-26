import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite connection for the whole app.
///
/// Widgets never open the database themselves; repositories ask this helper.
/// [close] awaits shutdown and clears the cached handle so the next call
/// to [database] reopens cleanly.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'budget_bites.db';
  static const _dbVersion = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    _opening ??= _open();
    _db = await _opening!;
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, _dbName),
      version: _dbVersion,
      onConfigure: (db) async {
        // Required so ON DELETE CASCADE works for meal -> purchases.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        typical_price REAL NOT NULL CHECK (typical_price > 0 AND typical_price <= 100),
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        price_paid REAL NOT NULL CHECK (price_paid >= 0 AND price_paid <= 100),
        purchased_at TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK (status IN ('in_progress', 'logged')),
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_purchases_meal ON purchases (meal_id)');
    await db.execute('CREATE INDEX idx_purchases_date ON purchases (purchased_at)');
    await _seed(db);
  }

  /// Small demo catalog: three meals and two history records.
  Future<void> _seed(Database db) async {
    final now = DateTime.now();
    String daysAgo(int d) =>
        DateTime(now.year, now.month, now.day - d, 12, 30).toIso8601String();

    final bowl = await db.insert('meals', {
      'name': 'Chicken burrito bowl',
      'location': 'Student Center',
      'category': 'Lunch',
      'typical_price': 9.50,
      'created_at': now.toIso8601String(),
    });
    await db.insert('meals', {
      'name': 'Bagel and coffee',
      'location': 'Library cafe',
      'category': 'Breakfast',
      'typical_price': 5.25,
      'created_at': now.toIso8601String(),
    });
    await db.insert('meals', {
      'name': 'Pad thai',
      'location': 'Food truck row',
      'category': 'Dinner',
      'typical_price': 11.00,
      'created_at': now.toIso8601String(),
    });
    await db.insert('purchases', {
      'meal_id': bowl,
      'price_paid': 9.25,
      'purchased_at': daysAgo(3),
      'note': 'Lunch special',
      'status': 'logged',
    });
    await db.insert('purchases', {
      'meal_id': bowl,
      'price_paid': 10.40,
      'purchased_at': daysAgo(1),
      'note': 'Added guac',
      'status': 'logged',
    });
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    _opening = null;
    if (db != null && db.isOpen) await db.close();
  }
}
