import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_edit_expense_sheet.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/kpi_summary_grid.dart';
import '../widgets/monthly_bar_chart.dart';

/// Interactive financial analytics dashboard powered by `fl_chart`.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    final monthlyExpenses = expenseProvider.monthlyExpenses;
    final categoryTotals = expenseProvider.categoryTotals;
    final monthlyPoints = expenseProvider.lastSixMonthsTotals;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: Builder(
            builder: (context) {
              if (expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (expenseProvider.errorMessage != null) {
                return ErrorStateView(
                  message: expenseProvider.errorMessage!,
                  onRetry: expenseProvider.loadExpenses,
                );
              }
              if (expenseProvider.allExpenses.isEmpty) {
                return EmptyStateView(
                  icon: Icons.bar_chart_rounded,
                  title: 'No spending data yet',
                  subtitle:
                      'Log your first expense to unlock interactive category charts and 6-month trends.',
                  actionLabel: 'Add Expense',
                  onAction: () => showAddEditExpenseModal(context),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Previous month',
                          onPressed: expenseProvider.previousMonth,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text(
                          _monthFormat.format(expenseProvider.selectedMonth),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Next month',
                          onPressed: expenseProvider.nextMonth,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KpiSummaryGrid(
                      monthlyTotal: expenseProvider.monthlyTotal,
                      dailyAverage: expenseProvider.dailyAverage,
                      topCategory: expenseProvider.topCategory,
                      transactionCount: monthlyExpenses.length,
                      baseCurrency: currencyProvider.baseCurrency,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final pieWidget = categoryTotals.isEmpty
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: EmptyStateView(
                                    icon: Icons.pie_chart_outline_rounded,
                                    title: 'No expenses in this month',
                                    subtitle:
                                        'Switch months or add an expense to inspect category breakdown.',
                                  ),
                                ),
                              )
                            : CategoryPieChart(
                                categoryTotals: categoryTotals,
                                monthlyTotal: expenseProvider.monthlyTotal,
                                baseCurrency: currencyProvider.baseCurrency,
                              );

                        final barWidget = MonthlyBarChart(
                          monthlyPoints: monthlyPoints,
                          baseCurrency: currencyProvider.baseCurrency,
                        );

                        if (constraints.maxWidth >= AppBreakpoints.tablet) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: pieWidget),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: barWidget),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            pieWidget,
                            const SizedBox(height: AppSpacing.md),
                            barWidget,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
