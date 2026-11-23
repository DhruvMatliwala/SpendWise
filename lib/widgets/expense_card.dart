import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../models/expense.dart';

/// Swipeable transaction card displaying category badge, amounts, and notes.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.baseCurrency,
    required this.onTap,
    required this.onDismissed,
  });

  final Expense expense;
  final String baseCurrency;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryMeta = ExpenseCategory.fromLabel(expense.category);
    final isForeignCurrency =
        expense.currency.toUpperCase() != baseCurrency.toUpperCase();

    return Dismissible(
      key: ValueKey<String>('expense-${expense.id ?? expense.hashCode}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryMeta.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    categoryMeta.icon,
                    color: categoryMeta.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        expense.notes.trim().isEmpty
                            ? '${categoryMeta.label} • ${_dateFormat.format(expense.date)}'
                            : '${categoryMeta.label} • ${_dateFormat.format(expense.date)} • ${expense.notes.trim()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      SupportedCurrency.formatAmount(
                        expense.convertedAmountInBase,
                        baseCurrency,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isForeignCurrency) ...[
                      const SizedBox(height: 2),
                      Text(
                        SupportedCurrency.formatAmount(
                          expense.amount,
                          expense.currency,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
