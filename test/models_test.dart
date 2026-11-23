import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/category_budget.dart';
import 'package:spendwise/models/currency_rate.dart';
import 'package:spendwise/models/expense.dart';

void main() {
  group('Expense serialization', () {
    test('toMap and fromMap roundtrip preserves all fields', () {
      final date = DateTime(2026, 11, 23, 14, 30);
      final expense = Expense(
        id: 42,
        title: 'Airport Cab',
        amount: 25.0,
        currency: 'USD',
        convertedAmountInBase: 2110.0,
        category: 'Travel',
        date: date,
        notes: 'Terminal 2 pickup',
      );

      final map = expense.toMap();
      final decoded = Expense.fromMap(map);

      expect(decoded, equals(expense));
      expect(decoded.id, 42);
      expect(decoded.convertedAmountInBase, 2110.0);
    });

    test('toJson and fromJson roundtrip preserves all fields', () {
      final date = DateTime(2026, 11, 20, 9, 15);
      final expense = Expense(
        id: 7,
        title: 'Cloud Hosting',
        amount: 1200.50,
        currency: 'INR',
        convertedAmountInBase: 1200.50,
        category: 'Bills',
        date: date,
        notes: 'Monthly server bill',
      );

      final decoded = Expense.fromJson(expense.toJson());
      expect(decoded, equals(expense));
    });

    test('copyWith with clearId resets id to null', () {
      final expense = Expense(
        id: 10,
        title: 'Coffee',
        amount: 250,
        currency: 'INR',
        convertedAmountInBase: 250,
        category: 'Food',
        date: DateTime(2026, 11, 1),
      );

      final copy = expense.copyWith(clearId: true, title: 'Latte');
      expect(copy.id, isNull);
      expect(copy.title, 'Latte');
    });
  });

  group('CategoryBudget and thresholds', () {
    test('toMap/fromMap and toJson/fromJson roundtrip', () {
      const budget = CategoryBudget(category: 'Food', monthlyLimit: 8000);
      expect(CategoryBudget.fromMap(budget.toMap()), equals(budget));
      expect(CategoryBudget.fromJson(budget.toJson()), equals(budget));
    });

    test('evaluateBudgetStatus classifies safe, warning, and exceeded', () {
      expect(
        evaluateBudgetStatus(spent: 7999, limit: 10000),
        BudgetStatus.safe,
      );
      expect(
        evaluateBudgetStatus(spent: 8000, limit: 10000),
        BudgetStatus.warning,
      );
      expect(
        evaluateBudgetStatus(spent: 9999, limit: 10000),
        BudgetStatus.warning,
      );
      expect(
        evaluateBudgetStatus(spent: 10000, limit: 10000),
        BudgetStatus.exceeded,
      );
      expect(
        evaluateBudgetStatus(spent: 12500, limit: 10000),
        BudgetStatus.exceeded,
      );
    });

    test('detectCrossedBudgetThreshold triggers only when crossing 80% or 100%', () {
      expect(
        detectCrossedBudgetThreshold(
          previousSpent: 750,
          newSpent: 820,
          limit: 1000,
        ),
        BudgetAlertLevel.warning80,
      );
      expect(
        detectCrossedBudgetThreshold(
          previousSpent: 820,
          newSpent: 900,
          limit: 1000,
        ),
        isNull,
      );
      expect(
        detectCrossedBudgetThreshold(
          previousSpent: 900,
          newSpent: 1050,
          limit: 1000,
        ),
        BudgetAlertLevel.exceeded100,
      );
    });
  });

  group('CurrencyRates', () {
    test('fromApiJson parses rates and converts foreign amounts to base', () {
      final apiPayload = <String, dynamic>{
        'result': 'success',
        'base_code': 'INR',
        'time_last_update_unix': 1763856000,
        'rates': <String, dynamic>{
          'INR': 1,
          'USD': 0.012,
          'EUR': 0.011,
        },
      };

      final rates = CurrencyRates.fromApiJson(apiPayload);
      expect(rates.baseCurrency, 'INR');
      expect(rates.isFromCache, isFalse);
      expect(rates.convertToBase(12.0, 'USD'), closeTo(1000.0, 0.001));
      expect(rates.convertToBase(500.0, 'INR'), 500.0);
    });

    test('rebasedTo re-anchors rates to a new base currency offline', () {
      final inrRates = CurrencyRates(
        baseCurrency: 'INR',
        rates: const {'INR': 1.0, 'USD': 0.012, 'EUR': 0.011},
        lastUpdated: DateTime(2026, 11, 23),
      );

      final usdRates = inrRates.rebasedTo('USD');
      expect(usdRates.baseCurrency, 'USD');
      expect(usdRates.rateFor('USD'), 1.0);
      expect(usdRates.rateFor('INR'), closeTo(83.333, 0.01));
    });

    test('toJson and fromJson cache roundtrip marks isFromCache true', () {
      final rates = CurrencyRates(
        baseCurrency: 'INR',
        rates: const {'INR': 1.0, 'USD': 0.012},
        lastUpdated: DateTime(2026, 11, 23, 12),
      );

      final restored = CurrencyRates.fromJson(rates.toJson());
      expect(restored.baseCurrency, 'INR');
      expect(restored.isFromCache, isTrue);
      expect(restored.rates['USD'], 0.012);
    });
  });
}
