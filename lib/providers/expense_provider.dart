import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../db/database_helper.dart';
import '../models/expense.dart';
import 'currency_provider.dart';

/// Holds a month label anchor and total spend for trend charts.
typedef MonthlySpendPoint = ({DateTime month, double total});

/// Manages offline-first SQLite expenses, filters, and analytics aggregations.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper.instance {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  final DatabaseHelper _db;

  List<Expense> _allExpenses = const [];
  late DateTime _selectedMonth;
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get allExpenses => _allExpenses;
  DateTime get selectedMonth => _selectedMonth;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// All expenses belonging to [_selectedMonth] (unfiltered by search/category).
  List<Expense> get monthlyExpenses {
    return _allExpenses
        .where(
          (expense) =>
              expense.date.year == _selectedMonth.year &&
              expense.date.month == _selectedMonth.month,
        )
        .toList(growable: false);
  }

  /// Expenses in [_selectedMonth] matching active category and search query.
  List<Expense> get filteredExpenses {
    final query = _searchQuery.trim().toLowerCase();
    return monthlyExpenses.where((expense) {
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final inTitle = expense.title.toLowerCase().contains(query);
        final inNotes = expense.notes.toLowerCase().contains(query);
        return inTitle || inNotes;
      }
      return true;
    }).toList(growable: false);
  }

  /// Total base-currency spending for [_selectedMonth].
  double get monthlyTotal => monthlyExpenses.fold(
        0.0,
        (sum, expense) => sum + expense.convertedAmountInBase,
      );

  /// Average daily spending for [_selectedMonth].
  double get dailyAverage {
    final expenses = monthlyExpenses;
    if (expenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final int daysDivisor;
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) {
      daysDivisor = now.day;
    } else {
      daysDivisor = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      ).day;
    }
    return monthlyTotal / (daysDivisor < 1 ? 1 : daysDivisor);
  }

  /// Category-to-total spending map for [_selectedMonth], sorted highest first.
  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in monthlyExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0.0) + expense.convertedAmountInBase;
    }
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(sortedEntries);
  }

  /// Highest-spending category entry for [_selectedMonth], or `null` if empty.
  MapEntry<String, double>? get topCategory {
    final totals = categoryTotals;
    if (totals.isEmpty) return null;
    return totals.entries.first;
  }

  /// Spending totals for the 6-month window ending at [_selectedMonth].
  List<MonthlySpendPoint> get lastSixMonthsTotals {
    final points = <MonthlySpendPoint>[];
    for (int offset = 5; offset >= 0; offset--) {
      final monthDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - offset,
      );
      final total = _allExpenses
          .where(
            (expense) =>
                expense.date.year == monthDate.year &&
                expense.date.month == monthDate.month,
          )
          .fold(0.0, (sum, expense) => sum + expense.convertedAmountInBase);
      points.add((month: monthDate, total: total));
    }
    return points;
  }

  /// Computes total spending in base currency for [category] in [month].
  double spentForCategoryInMonth(String category, DateTime month) {
    return _allExpenses
        .where(
          (expense) =>
              expense.category == category &&
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .fold(0.0, (sum, expense) => sum + expense.convertedAmountInBase);
  }

  /// Loads all expenses from SQLite.
  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allExpenses = await _db.getAllExpenses();
    } catch (error) {
      _errorMessage = 'Failed to load expenses: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a new [expense] in SQLite and updates state.
  Future<Expense> addExpense(Expense expense) async {
    final insertedId = await _db.insertExpense(expense);
    final saved = expense.copyWith(id: insertedId);
    _allExpenses = _sorted([saved, ..._allExpenses]);
    notifyListeners();
    return saved;
  }

  /// Updates an existing [expense] in SQLite and memory.
  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    _allExpenses = _sorted(
      _allExpenses
          .map((item) => item.id == expense.id ? expense : item)
          .toList(growable: false),
    );
    notifyListeners();
  }

  /// Deletes the expense matching [id] and returns it so the caller can offer Undo.
  Future<Expense?> deleteExpense(int id) async {
    Expense? removed;
    for (final item in _allExpenses) {
      if (item.id == id) {
        removed = item;
        break;
      }
    }
    if (removed == null) return null;

    await _db.deleteExpense(id);
    _allExpenses =
        _allExpenses.where((item) => item.id != id).toList(growable: false);
    notifyListeners();
    return removed;
  }

  /// Re-inserts a previously deleted [expense] (used for Undo snackbar).
  Future<void> restoreExpense(Expense expense) async {
    final restoredId = await _db.insertExpense(expense.copyWith(clearId: true));
    final restored = expense.copyWith(id: restoredId);
    _allExpenses = _sorted([restored, ..._allExpenses]);
    notifyListeners();
  }

  /// Recomputes `convertedAmountInBase` for all stored expenses after a base currency switch.
  Future<void> reconvertAllToBase(CurrencyProvider currencyProvider) async {
    if (_allExpenses.isEmpty) return;

    final dbUpdates = <int, double>{};
    final updatedList = <Expense>[];

    for (final expense in _allExpenses) {
      final converted = currencyProvider.convertToBase(
        expense.amount,
        expense.currency,
      );
      updatedList.add(expense.copyWith(convertedAmountInBase: converted));
      if (expense.id != null) {
        dbUpdates[expense.id!] = converted;
      }
    }

    await _db.updateConvertedAmounts(dbUpdates);
    _allExpenses = updatedList;
    notifyListeners();
  }

  /// Navigates one month backward.
  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  /// Navigates one month forward.
  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  /// Sets the active month filter.
  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  /// Sets or clears the category filter chip (`null` shows all categories).
  void setSelectedCategory(String? category) {
    if (category != null && !ExpenseCategory.labels.contains(category)) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  /// Updates the live title/notes search query.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// Clears search and category filters.
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    notifyListeners();
  }

  List<Expense> _sorted(List<Expense> items) {
    final copy = List<Expense>.from(items)
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return (b.id ?? 0).compareTo(a.id ?? 0);
      });
    return List.unmodifiable(copy);
  }
}
