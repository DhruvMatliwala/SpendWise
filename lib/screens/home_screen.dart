import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/category_budget.dart';
import '../providers/budget_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/csv_export_service.dart';
import '../widgets/add_edit_expense_sheet.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/expense_card.dart';

/// Primary expense ledger screen with month filter, search, alerts, and CSV export.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  final CsvExportService _csvExportService = const CsvExportService();

  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv(
    BuildContext context,
    ExpenseProvider expenseProvider,
    CurrencyProvider currencyProvider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final items = expenseProvider.filteredExpenses;
    if (items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No expenses to export for the current view.'),
        ),
      );
      return;
    }

    final periodLabel = _monthFormat.format(expenseProvider.selectedMonth);
    try {
      await _csvExportService.exportAndShareCsv(
        expenses: items,
        baseCurrency: currencyProvider.baseCurrency,
        periodLabel: periodLabel,
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('CSV export failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = SpendWiseColors.of(context);

    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final filtered = expenseProvider.filteredExpenses;
    final monthlyTotal = expenseProvider.monthlyTotal;
    final categoryTotals = expenseProvider.categoryTotals;

    final alertUsages = <BudgetUsage>[];
    for (final category in ExpenseCategory.labels) {
      final usage = budgetProvider.usageFor(
        category,
        categoryTotals[category] ?? 0.0,
      );
      if (usage != null && usage.status != BudgetStatus.safe) {
        alertUsages.add(usage);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SpendWise',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV statement',
            onPressed: () =>
                _exportCsv(context, expenseProvider, currencyProvider),
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            onPressed: themeProvider.toggleTheme,
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.loadExpenses();
              await budgetProvider.loadBudgets();
              await currencyProvider.refreshRates();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MonthSelectorBar(
                          label:
                              _monthFormat.format(expenseProvider.selectedMonth),
                          onPrevious: expenseProvider.previousMonth,
                          onNext: expenseProvider.nextMonth,
                          onResetToCurrent: () =>
                              expenseProvider.setSelectedMonth(DateTime.now()),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MonthlySummaryHeroCard(
                          monthlyTotal: monthlyTotal,
                          totalBudget: budgetProvider.totalMonthlyBudget,
                          transactionCount:
                              expenseProvider.monthlyExpenses.length,
                          baseCurrency: currencyProvider.baseCurrency,
                          isOfflineFallback: currencyProvider.isOfflineFallback,
                        ),
                        if (alertUsages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _BudgetAlertBanner(
                            alerts: alertUsages,
                            semanticColors: semanticColors,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _searchController,
                          onChanged: expenseProvider.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search expenses by title or note...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: expenseProvider.searchQuery.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      expenseProvider.setSearchQuery('');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CategoryFilterChips(
                      selectedCategory: expenseProvider.selectedCategory,
                      onSelected: expenseProvider.setSelectedCategory,
                    ),
                  ),
                ),
                if (expenseProvider.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (expenseProvider.errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorStateView(
                      message: expenseProvider.errorMessage!,
                      onRetry: expenseProvider.loadExpenses,
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
                      icon: Icons.receipt_long_rounded,
                      title: expenseProvider.monthlyExpenses.isEmpty
                          ? 'No expenses in ${_monthFormat.format(expenseProvider.selectedMonth)}'
                          : 'No matching expenses',
                      subtitle: expenseProvider.monthlyExpenses.isEmpty
                          ? 'Tap Add Expense to log your first offline-first transaction.'
                          : 'Try adjusting your search query or clearing category filters.',
                      actionLabel: expenseProvider.monthlyExpenses.isEmpty
                          ? 'Add Expense'
                          : 'Clear Filters',
                      onAction: () {
                        if (expenseProvider.monthlyExpenses.isEmpty) {
                          showAddEditExpenseModal(context);
                        } else {
                          _searchController.clear();
                          expenseProvider.clearFilters();
                        }
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      96,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final expense = filtered[index];
                        return ExpenseCard(
                          expense: expense,
                          baseCurrency: currencyProvider.baseCurrency,
                          onTap: () => showAddEditExpenseModal(
                            context,
                            existing: expense,
                          ),
                          onDismissed: () async {
                            final id = expense.id;
                            if (id == null) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final removed =
                                await expenseProvider.deleteExpense(id);
                            if (removed == null || !context.mounted) return;
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Deleted "${removed.title}"'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    textColor: colorScheme.inversePrimary,
                                    onPressed: () {
                                      expenseProvider.restoreExpense(removed);
                                    },
                                  ),
                                ),
                              );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSelectorBar extends StatelessWidget {
  const _MonthSelectorBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onResetToCurrent,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResetToCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          tooltip: 'Previous month',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        InkWell(
          onTap: onResetToCurrent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Next month',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _MonthlySummaryHeroCard extends StatelessWidget {
  const _MonthlySummaryHeroCard({
    required this.monthlyTotal,
    required this.totalBudget,
    required this.transactionCount,
    required this.baseCurrency,
    required this.isOfflineFallback,
  });

  final double monthlyTotal;
  final double totalBudget;
  final int transactionCount;
  final String baseCurrency;
  final bool isOfflineFallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasBudget = totalBudget > 0;
    final ratio = hasBudget ? (monthlyTotal / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Spend',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  isOfflineFallback
                      ? '$baseCurrency • Cached FX'
                      : '$baseCurrency • Live FX',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            SupportedCurrency.formatAmount(monthlyTotal, baseCurrency),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            transactionCount == 1
                ? '1 transaction logged'
                : '$transactionCount transactions logged',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          if (hasBudget) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Combined budget: ${SupportedCurrency.formatAmount(totalBudget, baseCurrency)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetAlertBanner extends StatelessWidget {
  const _BudgetAlertBanner({
    required this.alerts,
    required this.semanticColors,
  });

  final List<BudgetUsage> alerts;
  final SpendWiseColors semanticColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasExceeded =
        alerts.any((usage) => usage.status == BudgetStatus.exceeded);
    final accent =
        hasExceeded ? semanticColors.exceeded : semanticColors.warning;
    final summary = alerts
        .map((usage) => '${usage.category} (${usage.percentage}%)')
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            hasExceeded ? Icons.error_rounded : Icons.warning_amber_rounded,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasExceeded
                  ? 'Budget exceeded: $summary'
                  : 'Approaching budget limit: $summary',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
