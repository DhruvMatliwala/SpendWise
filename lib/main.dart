import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/budget_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpendWiseApp());
}

/// Root SpendWise application widget configuring themes and state providers.
class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..initialize(),
        ),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider()..initialize(),
        ),
        ChangeNotifierProvider<BudgetProvider>(
          create: (_) => BudgetProvider()..loadBudgets(),
        ),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) => ExpenseProvider()..loadExpenses(),
        ),
      ],
      child: const _SpendWiseMaterialApp(),
    );
  }
}

class _SpendWiseMaterialApp extends StatelessWidget {
  const _SpendWiseMaterialApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
