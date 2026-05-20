import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = true;

  // Primary palette - deep ocean blue
  static Color get primary => isDarkMode ? const Color(0xFF0D47A1) : const Color(0xFF1565C0);
  static Color get primaryLight => isDarkMode ? const Color(0xFF1565C0) : const Color(0xFF1976D2);
  static Color get primaryDark => isDarkMode ? const Color(0xFF0A2F6B) : const Color(0xFF0D47A1);

  // Accent - cyan/teal water
  static Color get accent => const Color(0xFF00BCD4);
  static Color get accentLight => const Color(0xFF4DD0E1);
  static Color get accentDark => const Color(0xFF0097A7);

  // Background
  static Color get bgDark => isDarkMode ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC); // Elegant slate 50
  static Color get bgCard => isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF); // Pure white in light mode
  static Color get bgCardLight => isDarkMode ? const Color(0xFF1C2536) : const Color(0xFFF1F5F9);
  static Color get bgSurface => isDarkMode ? const Color(0xFF162032) : const Color(0xFFF1F5F9);

  // Text
  static Color get textPrimary => isDarkMode ? const Color(0xFFE8F4FD) : const Color(0xFF0F172A); // Slate 900
  static Color get textSecondary => isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF334155); // Slate 700
  static Color get textMuted => isDarkMode ? const Color(0xFF546E7A) : const Color(0xFF64748B); // Slate 500

  // Sensor status colors
  static Color get good => const Color(0xFF00E676);
  static Color get warning => isDarkMode ? const Color(0xFFFFD600) : const Color(0xFFF59E0B); // Amber 500
  static Color get danger => const Color(0xFFFF1744);
  static Color get neutral => const Color(0xFF40C4FF);

  // Chart colors
  static Color get chartPH => const Color(0xFF7C4DFF);
  static Color get chartTurbidity => const Color(0xFF00BFA5);
  static Color get chartTemp => const Color(0xFFFF6D00);

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: isDarkMode 
      ? [const Color(0xFF0D47A1), const Color(0xFF00BCD4)]
      : [const Color(0xFF1565C0), const Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get bgGradient => LinearGradient(
    colors: isDarkMode
      ? [const Color(0xFF0A0E1A), const Color(0xFF0D1B2E)]
      : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)], // Soft slate gradient
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: isDarkMode
      ? [const Color(0xFF111827), const Color(0xFF1C2536)]
      : [const Color(0xFFFFFFFF), const Color(0xFFF9FAFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
