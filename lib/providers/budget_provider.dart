import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/category_budget.dart';

/// Manages per-category monthly budget limits and threshold alerts.
class BudgetProvider extends ChangeNotifier {
  BudgetProvider({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  final Map<String, double> _limits = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, double> get limits => Map.unmodifiable(_limits);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalMonthlyBudget =>
      _limits.values.fold(0.0, (sum, value) => sum + value);

  /// Loads all persisted monthly category budgets from SQLite.
  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.getAllBudgets();
      _limits
        ..clear()
        ..addEntries(rows.map((b) => MapEntry(b.category, b.monthlyLimit)));
    } catch (error) {
      _errorMessage = 'Failed to load budgets: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves or updates a monthly [monthlyLimit] for [category].
  Future<void> setBudget(String category, double monthlyLimit) async {
    final budget = CategoryBudget(
      category: category,
      monthlyLimit: monthlyLimit,
    );
    await _db.upsertBudget(budget);
    _limits[category] = monthlyLimit;
    notifyListeners();
  }

  /// Removes a configured budget limit for [category].
  Future<void> removeBudget(String category) async {
    await _db.deleteBudget(category);
    _limits.remove(category);
    notifyListeners();
  }

  /// Returns the configured monthly limit for [category], or `null` if unset.
  double? limitFor(String category) => _limits[category];

  /// Computes a [BudgetUsage] snapshot if a limit exists for [category].
  BudgetUsage? usageFor(String category, double spent) {
    final limit = _limits[category];
    if (limit == null || limit <= 0) return null;
    return BudgetUsage(
      category: category,
      monthlyLimit: limit,
      spent: spent,
    );
  }

  /// Checks whether [newSpent] crossed the 80% or 100% budget threshold.
  BudgetAlertLevel? checkThresholdCrossed({
    required String category,
    required double previousSpent,
    required double newSpent,
  }) {
    final limit = _limits[category];
    if (limit == null || limit <= 0) return null;
    return detectCrossedBudgetThreshold(
      previousSpent: previousSpent,
      newSpent: newSpent,
      limit: limit,
    );
  }
}
