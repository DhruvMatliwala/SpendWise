import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Responsive 2x2 / 4x1 grid of monthly spending KPI cards.
class KpiSummaryGrid extends StatelessWidget {
  const KpiSummaryGrid({
    super.key,
    required this.monthlyTotal,
    required this.dailyAverage,
    required this.topCategory,
    required this.transactionCount,
    required this.baseCurrency,
  });

  final double monthlyTotal;
  final double dailyAverage;
  final MapEntry<String, double>? topCategory;
  final int transactionCount;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final topCategoryEntry = topCategory;
    final items = [
      _KpiItem(
        label: 'Monthly Total',
        value: SupportedCurrency.formatAmount(monthlyTotal, baseCurrency),
        icon: Icons.account_balance_wallet_rounded,
        accent: Theme.of(context).colorScheme.primary,
      ),
      _KpiItem(
        label: 'Daily Average',
        value: SupportedCurrency.formatAmount(dailyAverage, baseCurrency),
        icon: Icons.trending_up_rounded,
        accent: ExpenseCategory.travel.color,
      ),
      _KpiItem(
        label: 'Top Category',
        value: topCategoryEntry?.key ?? 'None',
        subtitle: topCategoryEntry == null
            ? null
            : SupportedCurrency.formatAmount(
                topCategoryEntry.value,
                baseCurrency,
              ),
        icon: topCategoryEntry == null
            ? Icons.pie_chart_outline_rounded
            : ExpenseCategory.fromLabel(topCategoryEntry.key).icon,
        accent: topCategoryEntry == null
            ? Theme.of(context).colorScheme.secondary
            : ExpenseCategory.fromLabel(topCategoryEntry.key).color,
      ),
      _KpiItem(
        label: 'Transactions',
        value: '$transactionCount',
        subtitle: transactionCount == 1 ? '1 logged item' : 'logged items',
        icon: Icons.receipt_long_rounded,
        accent: ExpenseCategory.entertainment.color,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth >= AppBreakpoints.tablet ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _KpiCard(item: items[index]),
        );
      },
    );
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(item.icon, size: 18, color: item.accent),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
