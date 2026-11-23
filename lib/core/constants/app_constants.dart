import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Centralized spacing tokens used across SpendWise layouts.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Centralized corner radius tokens for cards, chips, and sheets.
abstract final class AppRadii {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

/// Responsive layout breakpoints based on available window width.
abstract final class AppBreakpoints {
  static const double tablet = 600.0;
  static const double desktop = 1024.0;
  static const double maxContentWidth = 1040.0;
}

/// Budget utilization threshold ratios.
abstract final class BudgetThresholds {
  static const double warning = 0.80;
  static const double exceeded = 1.00;
}

/// Supported expense categories with visual metadata.
enum ExpenseCategory {
  food('Food', Icons.restaurant_rounded, Color(0xFF10B981)),
  travel('Travel', Icons.flight_takeoff_rounded, Color(0xFF3B82F6)),
  bills('Bills', Icons.receipt_long_rounded, Color(0xFFF59E0B)),
  shopping('Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  health('Health', Icons.favorite_rounded, Color(0xFFEF4444)),
  entertainment('Entertainment', Icons.movie_rounded, Color(0xFF8B5CF6)),
  other('Other', Icons.category_rounded, Color(0xFF64748B));

  const ExpenseCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Ordered list of category labels.
  static List<String> get labels =>
      values.map((category) => category.label).toList(growable: false);

  /// Resolves a stored label to its matching [ExpenseCategory].
  static ExpenseCategory fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    for (final category in values) {
      if (category.label.toLowerCase() == normalized) {
        return category;
      }
    }
    return ExpenseCategory.other;
  }
}

/// Metadata and formatting helpers for supported currencies.
class SupportedCurrency {
  const SupportedCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimalDigits,
  });

  final String code;
  final String name;
  final String symbol;
  final int decimalDigits;

  static const String defaultBaseCode = 'INR';

  static const List<SupportedCurrency> all = [
    SupportedCurrency(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      decimalDigits: 2,
    ),
    SupportedCurrency(
      code: 'USD',
      name: 'US Dollar',
      symbol: r'$',
      decimalDigits: 2,
    ),
    SupportedCurrency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      decimalDigits: 2,
    ),
    SupportedCurrency(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      decimalDigits: 2,
    ),
    SupportedCurrency(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      decimalDigits: 2,
    ),
    SupportedCurrency(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      decimalDigits: 0,
    ),
  ];

  static List<String> get codes =>
      all.map((currency) => currency.code).toList(growable: false);

  /// Finds currency metadata by ISO code, defaulting to INR.
  static SupportedCurrency byCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final currency in all) {
      if (currency.code == normalized) {
        return currency;
      }
    }
    return all.first;
  }

  /// Returns the display symbol for [code].
  static String symbolFor(String code) => byCode(code).symbol;

  /// Formats [amount] using [code]'s currency symbol and precision.
  static String formatAmount(
    double amount,
    String code, {
    bool compact = false,
  }) {
    final currency = byCode(code);
    final displaySymbol =
        currency.code == 'AED' ? 'AED ' : currency.symbol;
    if (compact) {
      return NumberFormat.compactCurrency(
        symbol: displaySymbol,
        decimalDigits: currency.decimalDigits == 0 ? 0 : 1,
      ).format(amount);
    }
    return NumberFormat.currency(
      symbol: displaySymbol,
      decimalDigits: currency.decimalDigits,
    ).format(amount);
  }
}
