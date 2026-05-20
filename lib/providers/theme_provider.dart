import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_preference';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to dark mode if not set
    final isDark = prefs.getBool(_themeKey) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.isDarkMode = isDark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      AppColors.isDarkMode = false;
      await prefs.setBool(_themeKey, false);
    } else {
      _themeMode = ThemeMode.dark;
      AppColors.isDarkMode = true;
      await prefs.setBool(_themeKey, true);
    }
    notifyListeners();
  }
}
