import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

/// Budget utilization health states.
enum BudgetStatus {
  safe,
  warning,
  exceeded,
}

/// Immediate threshold crossing notification levels.
enum BudgetAlertLevel {
  warning80,
  exceeded100,
}

/// Evaluates the [BudgetStatus] for a given [spent] and [limit].
BudgetStatus evaluateBudgetStatus({
  required double spent,
  required double limit,
}) {
  if (limit <= 0) return BudgetStatus.safe;
  final ratio = spent / limit;
  if (ratio >= BudgetThresholds.exceeded) return BudgetStatus.exceeded;
  if (ratio >= BudgetThresholds.warning) return BudgetStatus.warning;
  return BudgetStatus.safe;
}

/// Detects whether adding/updating an expense crossed the 80% or 100% threshold.
BudgetAlertLevel? detectCrossedBudgetThreshold({
  required double previousSpent,
  required double newSpent,
  required double limit,
}) {
  if (limit <= 0 || newSpent <= previousSpent) return null;
  final previousRatio = previousSpent / limit;
  final newRatio = newSpent / limit;

  if (previousRatio < BudgetThresholds.exceeded &&
      newRatio >= BudgetThresholds.exceeded) {
    return BudgetAlertLevel.exceeded100;
  }
  if (previousRatio < BudgetThresholds.warning &&
      newRatio >= BudgetThresholds.warning) {
    return BudgetAlertLevel.warning80;
  }
  return null;
}

/// Immutable monthly budget limit for a single expense category.
@immutable
class CategoryBudget {
  const CategoryBudget({
    required this.category,
    required this.monthlyLimit,
  });

  final String category;
  final double monthlyLimit;

  CategoryBudget copyWith({
    String? category,
    double? monthlyLimit,
  }) {
    return CategoryBudget(
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'category': category,
      'monthly_limit': monthlyLimit,
    };
  }

  factory CategoryBudget.fromMap(Map<String, Object?> map) {
    return switch (map) {
      {
        'category': final String category,
        'monthly_limit': final num monthlyLimit,
      } =>
        CategoryBudget(
          category: category,
          monthlyLimit: monthlyLimit.toDouble(),
        ),
      _ => throw const FormatException('Invalid SQLite budget record.'),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
    };
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'category': final String category,
        'monthlyLimit': final num monthlyLimit,
      } =>
        CategoryBudget(
          category: category,
          monthlyLimit: monthlyLimit.toDouble(),
        ),
      _ => throw const FormatException('Invalid JSON budget payload.'),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryBudget &&
        other.category == category &&
        other.monthlyLimit == monthlyLimit;
  }

  @override
  int get hashCode => Object.hash(category, monthlyLimit);
}

/// Computed monthly budget utilization snapshot for UI presentation.
@immutable
class BudgetUsage {
  const BudgetUsage({
    required this.category,
    required this.monthlyLimit,
    required this.spent,
  });

  final String category;
  final double monthlyLimit;
  final double spent;

  double get ratio => monthlyLimit <= 0 ? 0.0 : spent / monthlyLimit;
  double get progressClamped => ratio.clamp(0.0, 1.0);
  int get percentage => (ratio * 100).round();
  double get remaining => monthlyLimit - spent;

  BudgetStatus get status =>
      evaluateBudgetStatus(spent: spent, limit: monthlyLimit);
}
