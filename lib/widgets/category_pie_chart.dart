import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Interactive category spending pie chart with touch expansion and legend.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    required this.monthlyTotal,
    required this.baseCurrency,
  });

  final Map<String, double> categoryTotals;
  final double monthlyTotal;
  final String baseCurrency;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = widget.categoryTotals.entries.toList(growable: false);
    final total = widget.monthlyTotal <= 0 ? 1.0 : widget.monthlyTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap a slice to inspect category share',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 48,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            final touchedSection =
                                pieTouchResponse?.touchedSection;
                            if (!event.isInterestedForInteractions ||
                                touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = touchedSection.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(entries.length, (index) {
                        final entry = entries[index];
                        final categoryMeta =
                            ExpenseCategory.fromLabel(entry.key);
                        final isTouched = index == _touchedIndex;
                        final percentage = (entry.value / total) * 100;

                        return PieChartSectionData(
                          color: categoryMeta.color,
                          value: entry.value,
                          radius: isTouched ? 64 : 54,
                          title: percentage >= 6
                              ? '${percentage.toStringAsFixed(0)}%'
                              : '',
                          titleStyle: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }),
                    ),
                  ),
                  IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _touchedIndex >= 0 && _touchedIndex < entries.length
                              ? entries[_touchedIndex].key
                              : 'Total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          SupportedCurrency.formatAmount(
                            _touchedIndex >= 0 &&
                                    _touchedIndex < entries.length
                                ? entries[_touchedIndex].value
                                : widget.monthlyTotal,
                            widget.baseCurrency,
                            compact: true,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              children: List.generate(entries.length, (index) {
                final entry = entries[index];
                final categoryMeta = ExpenseCategory.fromLabel(entry.key);
                final percentage = (entry.value / total) * 100;
                final isHighlighted = index == _touchedIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? categoryMeta.color.withValues(alpha: 0.14)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: categoryMeta.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          categoryMeta.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isHighlighted
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        SupportedCurrency.formatAmount(
                          entry.value,
                          widget.baseCurrency,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
