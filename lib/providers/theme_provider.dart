import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's Material 3 dark/light theme preference.
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'spendwise_theme_mode_v1';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Restores the saved theme mode from `SharedPreferences`.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themePrefKey);
    if (stored == 'light') {
      _themeMode = ThemeMode.light;
    } else if (stored == 'dark') {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  /// Toggles between dark slate and light themes.
  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  /// Updates and persists [mode].
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themePrefKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }
}
