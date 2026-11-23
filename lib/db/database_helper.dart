import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';

/// Singleton SQLite helper managing offline-first persistence for expenses and budgets.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  static const String _databaseName = 'spendwise.db';
  static const int _databaseVersion = 1;

  static const String _expensesTable = 'expenses';
  static const String _budgetsTable = 'budgets';

  Database? _database;

  /// Lazily opens and caches the SQLite database instance.
  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _databaseName);
    return openDatabase(
      fullPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        converted_amount_in_base REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_date ON $_expensesTable (date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON $_expensesTable (category)',
    );

    await db.execute('''
      CREATE TABLE $_budgetsTable (
        category TEXT PRIMARY KEY,
        monthly_limit REAL NOT NULL
      )
    ''');
  }

  /// Inserts a new [Expense] and returns its assigned row ID.
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(
      _expensesTable,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing [Expense] matching [Expense.id].
  Future<int> updateExpense(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError('Cannot update an expense without an id.');
    }
    final db = await database;
    return db.update(
      _expensesTable,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes the expense matching [id] and returns the number of rows deleted.
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(
      _expensesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all stored expenses ordered newest first.
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query(
      _expensesTable,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList(growable: false);
  }

  /// Returns expenses falling within [year] and [month].
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final db = await database;
    final start = DateTime(year, month).toIso8601String();
    final end = DateTime(year, month + 1).toIso8601String();
    final rows = await db.query(
      _expensesTable,
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList(growable: false);
  }

  /// Batch-updates `converted_amount_in_base` when the base currency changes.
  Future<void> updateConvertedAmounts(Map<int, double> updates) async {
    if (updates.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final entry in updates.entries) {
      batch.update(
        _expensesTable,
        {'converted_amount_in_base': entry.value},
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Inserts or replaces a category's monthly budget limit.
  Future<void> upsertBudget(CategoryBudget budget) async {
    final db = await database;
    await db.insert(
      _budgetsTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes a category budget limit.
  Future<int> deleteBudget(String category) async {
    final db = await database;
    return db.delete(
      _budgetsTable,
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  /// Fetches all persisted category budgets.
  Future<List<CategoryBudget>> getAllBudgets() async {
    final db = await database;
    final rows = await db.query(_budgetsTable);
    return rows.map(CategoryBudget.fromMap).toList(growable: false);
  }

  /// Closes the active database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
