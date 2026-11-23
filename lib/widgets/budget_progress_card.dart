import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/category_budget.dart';

/// Displays monthly budget progress, status badge, and quick edit/delete controls.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.monthlyLimit,
    required this.baseCurrency,
    required this.onEdit,
    this.onRemove,
  });

  final String category;
  final double spent;
  final double? monthlyLimit;
  final String baseCurrency;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semanticColors = SpendWiseColors.of(context);
    final categoryMeta = ExpenseCategory.fromLabel(category);

    final hasLimit = monthlyLimit != null && monthlyLimit! > 0;
    final usage = hasLimit
        ? BudgetUsage(
            category: category,
            monthlyLimit: monthlyLimit!,
            spent: spent,
          )
        : null;

    final Color statusColor;
    final String badgeLabel;
    if (usage == null) {
      statusColor = colorScheme.onSurfaceVariant;
      badgeLabel = 'No Limit';
    } else {
      switch (usage.status) {
        case BudgetStatus.safe:
          statusColor = semanticColors.safe;
          badgeLabel = '${usage.percentage}% Safe';
        case BudgetStatus.warning:
          statusColor = semanticColors.warning;
          badgeLabel = '${usage.percentage}% Warning';
        case BudgetStatus.exceeded:
          statusColor = semanticColors.exceeded;
          badgeLabel = '${usage.percentage}% Exceeded';
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryMeta.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(
                    categoryMeta.icon,
                    color: categoryMeta.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryMeta.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLimit
                            ? '${SupportedCurrency.formatAmount(spent, baseCurrency)} of ${SupportedCurrency.formatAmount(monthlyLimit!, baseCurrency)}'
                            : '${SupportedCurrency.formatAmount(spent, baseCurrency)} spent this month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    badgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (usage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: LinearProgressIndicator(
                  value: usage.progressClamped,
                  minHeight: 8,
                  backgroundColor:
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      usage.remaining >= 0
                          ? '${SupportedCurrency.formatAmount(usage.remaining, baseCurrency)} remaining'
                          : 'Overspent by ${SupportedCurrency.formatAmount(usage.remaining.abs(), baseCurrency)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: usage.remaining >= 0
                            ? colorScheme.onSurfaceVariant
                            : semanticColors.exceeded,
                        fontWeight: usage.remaining >= 0
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: onEdit,
                        child: const Text('Edit'),
                      ),
                      if (onRemove != null)
                        IconButton(
                          tooltip: 'Remove budget limit',
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Set Limit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
