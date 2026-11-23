import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/category_budget.dart';
import '../providers/budget_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/empty_state_view.dart';

/// Monthly per-category budget management screen with 80%/100% status badges.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  Future<void> _showLimitDialog(
    BuildContext context, {
    required String category,
    required double? existingLimit,
    required String baseCurrency,
  }) async {
    final budgetProvider = context.read<BudgetProvider>();
    final updatedLimit = await showDialog<double>(
      context: context,
      builder: (_) => _BudgetLimitDialog(
        category: category,
        existingLimit: existingLimit,
        baseCurrency: baseCurrency,
      ),
    );
    if (updatedLimit == null) return;
    await budgetProvider.setBudget(category, updatedLimit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = SpendWiseColors.of(context);

    final budgetProvider = context.watch<BudgetProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    final categoryTotals = expenseProvider.categoryTotals;
    final totalBudget = budgetProvider.totalMonthlyBudget;
    final budgetedSpend = budgetProvider.limits.keys.fold<double>(
      0.0,
      (sum, category) => sum + (categoryTotals[category] ?? 0.0),
    );

    final overallStatus = evaluateBudgetStatus(
      spent: budgetedSpend,
      limit: totalBudget,
    );
    final overallColor = switch (overallStatus) {
      BudgetStatus.safe => semanticColors.safe,
      BudgetStatus.warning => semanticColors.warning,
      BudgetStatus.exceeded => semanticColors.exceeded,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Budgets',
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
              if (budgetProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (budgetProvider.errorMessage != null) {
                return ErrorStateView(
                  message: budgetProvider.errorMessage!,
                  onRetry: budgetProvider.loadBudgets,
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Monthly Budget Overview',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _monthFormat.format(
                                          expenseProvider.selectedMonth,
                                        ),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.shield_outlined,
                                  color: totalBudget > 0
                                      ? overallColor
                                      : colorScheme.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (totalBudget > 0) ...[
                              Text(
                                '${SupportedCurrency.formatAmount(budgetedSpend, currencyProvider.baseCurrency)} / ${SupportedCurrency.formatAmount(totalBudget, currencyProvider.baseCurrency)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                child: LinearProgressIndicator(
                                  value: (budgetedSpend / totalBudget)
                                      .clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    overallColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Alerts trigger automatically at 80% (Warning) and 100% (Exceeded).',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ] else
                              Text(
                                'Set monthly spending limits below to receive automatic 80% warning and 100% exceeded alerts.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= AppBreakpoints.tablet;
                        final categories = ExpenseCategory.values;

                        if (!isWide) {
                          return Column(
                            children: categories.map((category) {
                              final limit =
                                  budgetProvider.limitFor(category.label);
                              final spent =
                                  categoryTotals[category.label] ?? 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: BudgetProgressCard(
                                  category: category.label,
                                  spent: spent,
                                  monthlyLimit: limit,
                                  baseCurrency: currencyProvider.baseCurrency,
                                  onEdit: () => _showLimitDialog(
                                    context,
                                    category: category.label,
                                    existingLimit: limit,
                                    baseCurrency: currencyProvider.baseCurrency,
                                  ),
                                  onRemove: limit == null
                                      ? null
                                      : () => budgetProvider
                                          .removeBudget(category.label),
                                ),
                              );
                            }).toList(growable: false),
                          );
                        }

                        final cardWidth =
                            (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: categories.map((category) {
                            final limit =
                                budgetProvider.limitFor(category.label);
                            final spent = categoryTotals[category.label] ?? 0.0;
                            return SizedBox(
                              width: cardWidth,
                              child: BudgetProgressCard(
                                category: category.label,
                                spent: spent,
                                monthlyLimit: limit,
                                baseCurrency: currencyProvider.baseCurrency,
                                onEdit: () => _showLimitDialog(
                                  context,
                                  category: category.label,
                                  existingLimit: limit,
                                  baseCurrency: currencyProvider.baseCurrency,
                                ),
                                onRemove: limit == null
                                    ? null
                                    : () => budgetProvider
                                        .removeBudget(category.label),
                              ),
                            );
                          }).toList(growable: false),
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

class _BudgetLimitDialog extends StatefulWidget {
  const _BudgetLimitDialog({
    required this.category,
    required this.existingLimit,
    required this.baseCurrency,
  });

  final String category;
  final double? existingLimit;
  final String baseCurrency;

  @override
  State<_BudgetLimitDialog> createState() => _BudgetLimitDialogState();
}

class _BudgetLimitDialogState extends State<_BudgetLimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingLimit != null
          ? widget.existingLimit!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;
    final parsed = double.parse(_controller.text.trim());
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.category} Budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monthly Limit (${widget.baseCurrency})',
            prefixText:
                '${SupportedCurrency.symbolFor(widget.baseCurrency)} ',
          ),
          validator: (value) {
            final parsed = double.tryParse(value?.trim() ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Enter a valid limit > 0';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
