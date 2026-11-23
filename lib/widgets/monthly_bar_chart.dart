import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../providers/expense_provider.dart';

/// Interactive 6-month spending trend bar chart with touch tooltips.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.monthlyPoints,
    required this.baseCurrency,
  });

  final List<MonthlySpendPoint> monthlyPoints;
  final String baseCurrency;

  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _tooltipMonthFormat = DateFormat('MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    double maxSpend = 0;
    for (final point in monthlyPoints) {
      if (point.total > maxSpend) {
        maxSpend = point.total;
      }
    }
    final chartMaxY = maxSpend <= 0 ? 100.0 : maxSpend * 1.25;
    final yInterval = chartMaxY / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '6-Month Spending Trend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Touch any bar to inspect monthly totals',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.inverseSurface,
                      tooltipRoundedRadius: AppRadii.sm,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = monthlyPoints[groupIndex];
                        final monthLabel =
                            _tooltipMonthFormat.format(point.month);
                        final formattedTotal = SupportedCurrency.formatAmount(
                          point.total,
                          baseCurrency,
                        );
                        return BarTooltipItem(
                          '$monthLabel\n$formattedTotal',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              child: Text(
                                '0',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(
                              SupportedCurrency.formatAmount(
                                value,
                                baseCurrency,
                                compact: true,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final isLatest = index == monthlyPoints.length - 1;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              _shortMonthFormat
                                  .format(monthlyPoints[index].month),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isLatest
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isLatest
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(monthlyPoints.length, (index) {
                    final point = monthlyPoints[index];
                    final isLatest = index == monthlyPoints.length - 1;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: point.total,
                          width: 22,
                          color: isLatest
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
