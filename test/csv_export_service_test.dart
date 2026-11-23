import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise/models/expense.dart';
import 'package:spendwise/services/csv_export_service.dart';

void main() {
  group('CsvExportService', () {
    const service = CsvExportService();

    test('generates header and formatted rows for multi-currency expenses', () {
      final expenses = [
        Expense(
          id: 1,
          title: 'Tokyo Rail Pass',
          amount: 1500,
          currency: 'JPY',
          convertedAmountInBase: 820.50,
          category: 'Travel',
          date: DateTime(2026, 11, 12),
          notes: 'Suica top-up',
        ),
      ];

      final csv = service.generateCsv(expenses, 'INR');
      final lines = csv.trim().split('\n');

      expect(lines.length, 2);
      expect(
        lines[0],
        'Date,Title,Category,Original Amount,Currency,Converted Amount (INR),Notes',
      );
      expect(
        lines[1],
        '2026-11-12,Tokyo Rail Pass,Travel,1500,JPY,820.50,Suica top-up',
      );
    });

    test('escapes commas and double quotes per RFC-4180', () {
      final expenses = [
        Expense(
          id: 2,
          title: 'Dinner, "Team" Meetup',
          amount: 45.5,
          currency: 'USD',
          convertedAmountInBase: 3840.20,
          category: 'Food',
          date: DateTime(2026, 11, 18),
          notes: 'Split 50/50, paid via card',
        ),
      ];

      final csv = service.generateCsv(expenses, 'INR');
      final lines = csv.trim().split('\n');

      expect(
        lines[1],
        '2026-11-18,"Dinner, ""Team"" Meetup",Food,45.50,USD,3840.20,"Split 50/50, paid via card"',
      );
    });
  });
}
