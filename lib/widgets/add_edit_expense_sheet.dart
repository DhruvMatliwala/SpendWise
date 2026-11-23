import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';

/// Opens [AddEditExpenseSheet], persists the expense, and triggers 80%/100% budget alerts.
Future<void> showAddEditExpenseModal(
  BuildContext context, {
  Expense? existing,
}) async {
  final expenseProvider = context.read<ExpenseProvider>();
  final budgetProvider = context.read<BudgetProvider>();
  final currencyProvider = context.read<CurrencyProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final semanticColors = SpendWiseColors.of(context);
  final colorScheme = Theme.of(context).colorScheme;

  final result = await AddEditExpenseSheet.show(
    context,
    existing: existing,
    defaultCurrency: currencyProvider.baseCurrency,
  );
  if (result == null) return;

  final previousSpent = expenseProvider.spentForCategoryInMonth(
    result.category,
    result.date,
  );

  if (existing == null) {
    await expenseProvider.addExpense(result);
  } else {
    await expenseProvider.updateExpense(result);
  }

  final newSpent = expenseProvider.spentForCategoryInMonth(
    result.category,
    result.date,
  );
  final alert = budgetProvider.checkThresholdCrossed(
    category: result.category,
    previousSpent: previousSpent,
    newSpent: newSpent,
  );

  if (alert == null) return;

  final limit = budgetProvider.limitFor(result.category) ?? 0;
  final usagePct = limit > 0 ? ((newSpent / limit) * 100).round() : 0;
  final formattedLimit = SupportedCurrency.formatAmount(
    limit,
    currencyProvider.baseCurrency,
  );
  final formattedSpent = SupportedCurrency.formatAmount(
    newSpent,
    currencyProvider.baseCurrency,
  );

  final isExceeded = alert == BudgetAlertLevel.exceeded100;
  final bannerColor =
      isExceeded ? semanticColors.exceeded : semanticColors.warning;
  final message = isExceeded
      ? 'Budget exceeded for ${result.category}: $formattedSpent / $formattedLimit ($usagePct%)'
      : 'Budget warning for ${result.category}: reached $usagePct% ($formattedSpent / $formattedLimit)';

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: bannerColor,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              isExceeded
                  ? Icons.error_rounded
                  : Icons.warning_amber_rounded,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Modal bottom sheet for creating or editing an [Expense].
class AddEditExpenseSheet extends StatefulWidget {
  const AddEditExpenseSheet({
    super.key,
    this.existing,
    required this.defaultCurrency,
  });

  final Expense? existing;
  final String defaultCurrency;

  /// Presents the sheet and returns the validated [Expense], or `null` if cancelled.
  static Future<Expense?> show(
    BuildContext context, {
    Expense? existing,
    required String defaultCurrency,
  }) {
    return showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AddEditExpenseSheet(
        existing: existing,
        defaultCurrency: defaultCurrency,
      ),
    );
  }

  @override
  State<AddEditExpenseSheet> createState() => _AddEditExpenseSheetState();
}

class _AddEditExpenseSheetState extends State<AddEditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _selectedCurrency;
  late String _selectedCategory;
  late DateTime _selectedDate;

  static final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _selectedCurrency = existing?.currency ?? widget.defaultCurrency;
    _selectedCategory = existing?.category ?? ExpenseCategory.food.label;
    _selectedDate = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  void _submit(CurrencyProvider currencyProvider) {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final converted = currencyProvider.convertToBase(amount, _selectedCurrency);

    final expense = Expense(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      amount: amount,
      currency: _selectedCurrency,
      convertedAmountInBase: converted,
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop(expense);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    final parsedAmount = double.tryParse(_amountController.text.trim());
    final showConversionPreview = parsedAmount != null &&
        parsedAmount > 0 &&
        _selectedCurrency != currencyProvider.baseCurrency;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + bottomInset,
      ),
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existing == null ? 'Add Expense' : 'Edit Expense',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Metro card recharge',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an expense title.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText:
                                '${SupportedCurrency.symbolFor(_selectedCurrency)} ',
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final parsed = double.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid amount > 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Currency',
                          ),
                          items: SupportedCurrency.all
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency.code,
                                  child: Text('${currency.code} (${currency.symbol})'),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCurrency = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (showConversionPreview) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.currency_exchange_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Converted: ${SupportedCurrency.formatAmount(currencyProvider.convertToBase(parsedAmount, _selectedCurrency), currencyProvider.baseCurrency)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: ExpenseCategory.values.map((category) {
                      final isSelected = _selectedCategory == category.label;
                      return ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : category.color,
                        ),
                        label: Text(category.label),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category.label;
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(_dateFormat.format(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Merchant, payment method, or split note',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => _submit(currencyProvider),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      widget.existing == null ? 'Save Expense' : 'Update Expense',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
