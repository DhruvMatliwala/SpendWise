import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/expense.dart';

/// Generates RFC-4180 CSV statements and shares them via the platform sheet.
class CsvExportService {
  const CsvExportService();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Formats [expenses] into a CSV string with [baseCurrency] conversions.
  String generateCsv(List<Expense> expenses, String baseCurrency) {
    final baseDigits = SupportedCurrency.byCode(baseCurrency).decimalDigits;
    final buffer = StringBuffer()
      ..writeln(
        'Date,Title,Category,Original Amount,Currency,'
        'Converted Amount ($baseCurrency),Notes',
      );

    for (final expense in expenses) {
      final originalDigits =
          SupportedCurrency.byCode(expense.currency).decimalDigits;
      final row = [
        _dateFormat.format(expense.date),
        _escapeField(expense.title),
        _escapeField(expense.category),
        expense.amount.toStringAsFixed(originalDigits),
        expense.currency.toUpperCase(),
        expense.convertedAmountInBase.toStringAsFixed(baseDigits),
        _escapeField(expense.notes),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Writes a `.csv` statement into temporary storage and triggers sharing.
  Future<String> exportAndShareCsv({
    required List<Expense> expenses,
    required String baseCurrency,
    required String periodLabel,
  }) async {
    final csvContent = generateCsv(expenses, baseCurrency);
    final directory = await getTemporaryDirectory();
    final sanitizedPeriod = periodLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final fileName = 'spendwise_${sanitizedPeriod.isEmpty ? 'statement' : sanitizedPeriod}.csv';
    final filePath = p.join(directory.path, fileName);

    final file = File(filePath);
    await file.writeAsString(csvContent, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'SpendWise Statement — $periodLabel',
      text: 'SpendWise expense statement for $periodLabel ($baseCurrency).',
    );

    return file.path;
  }

  String _escapeField(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
