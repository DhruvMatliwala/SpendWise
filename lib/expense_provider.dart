import 'package:flutter/foundation.dart';
import 'expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get totalExpense {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> breakdown = {};
    for (final exp in _expenses) {
      breakdown[exp.category] = (breakdown[exp.category] ?? 0.0) + exp.amount;
    }
    return breakdown;
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
