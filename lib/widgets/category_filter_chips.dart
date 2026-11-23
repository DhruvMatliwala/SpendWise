import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Horizontal scrollable category filter chip bar (`All` + 7 categories).
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: ExpenseCategory.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedCategory == null;
            return ChoiceChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (_) => onSelected(null),
            );
          }

          final category = ExpenseCategory.values[index - 1];
          final isSelected = selectedCategory == category.label;
          return ChoiceChip(
            avatar: Icon(
              category.icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimaryContainer : category.color,
            ),
            label: Text(category.label),
            selected: isSelected,
            onSelected: (_) =>
                onSelected(isSelected ? null : category.label),
          );
        },
      ),
    );
  }
}
