import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/csv_export_service.dart';

/// Application settings for base currency, live FX cache, theme, and CSV export.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final DateFormat _timestampFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static const CsvExportService _csvExportService = CsvExportService();

  Future<void> _changeBaseCurrency(
    BuildContext context,
    String newBase,
  ) async {
    final currencyProvider = context.read<CurrencyProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await currencyProvider.setBaseCurrency(newBase);
    await expenseProvider.reconvertAllToBase(currencyProvider);

    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Base currency updated to $newBase.'),
      ),
    );
  }

  Future<void> _exportStatement(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final currencyProvider = context.read<CurrencyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final monthly = expenseProvider.monthlyExpenses;
    if (monthly.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No expenses logged for the selected month.'),
        ),
      );
      return;
    }

    final periodLabel = _monthFormat.format(expenseProvider.selectedMonth);
    try {
      await _csvExportService.exportAndShareCsv(
        expenses: monthly,
        baseCurrency: currencyProvider.baseCurrency,
        periodLabel: periodLabel,
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to export CSV: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = SpendWiseColors.of(context);

    final currencyProvider = context.watch<CurrencyProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final lastUpdated = currencyProvider.lastUpdated;
    final formattedUpdated = lastUpdated != null
        ? _timestampFormat.format(lastUpdated.toLocal())
        : 'Not synced yet';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Text(
                'Currency & Exchange Rates',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: currencyProvider.baseCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Base Currency',
                          prefixIcon: Icon(Icons.currency_exchange_rounded),
                        ),
                        items: SupportedCurrency.all
                            .map(
                              (currency) => DropdownMenuItem<String>(
                                value: currency.code,
                                child: Text(
                                  '${currency.code} (${currency.symbol}) — ${currency.name}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            _changeBaseCurrency(context, value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (currencyProvider.isOfflineFallback
                                      ? semanticColors.warning
                                      : semanticColors.safe)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              currencyProvider.isOfflineFallback
                                  ? 'Offline Cache'
                                  : 'Live Rates',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: currencyProvider.isOfflineFallback
                                    ? semanticColors.warning
                                    : semanticColors.safe,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Last updated: $formattedUpdated',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (currencyProvider.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          currencyProvider.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: semanticColors.warning,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: SupportedCurrency.all
                            .where(
                              (c) => c.code != currencyProvider.baseCurrency,
                            )
                            .map((currency) {
                          final rate = currencyProvider.rateFor(currency.code);
                          return Chip(
                            label: Text(
                              '1 ${currencyProvider.baseCurrency} = ${rate.toStringAsFixed(currency.decimalDigits == 0 ? 2 : 4)} ${currency.code}',
                            ),
                          );
                        }).toList(growable: false),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.tonalIcon(
                        onPressed: currencyProvider.isLoading
                            ? null
                            : () async {
                                await currencyProvider.refreshRates();
                                await expenseProvider
                                    .reconvertAllToBase(currencyProvider);
                              },
                        icon: currencyProvider.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          currencyProvider.isLoading
                              ? 'Refreshing...'
                              : 'Refresh Live Rates',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Appearance',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: SwitchListTile(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                  ),
                  title: const Text('Dark Slate Theme'),
                  subtitle: const Text(
                    'Toggle between dark fintech slate and light mode',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Statements & Storage',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Export Monthly CSV Statement'),
                      subtitle: Text(
                        'Share ${_monthFormat.format(expenseProvider.selectedMonth)} transactions as .csv',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _exportStatement(context),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.storage_rounded),
                      title: Text('Offline-First SQLite Engine'),
                      subtitle: Text(
                        'All expenses and budgets are stored locally on your device.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
