import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - deep ocean blue
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0A2F6B);

  // Accent - cyan/teal water
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF4DD0E1);
  static const Color accentDark = Color(0xFF0097A7);

  // Background (dark mode)
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgCardLight = Color(0xFF1C2536);
  static const Color bgSurface = Color(0xFF162032);

  // Text
  static const Color textPrimary = Color(0xFFE8F4FD);
  static const Color textSecondary = Color(0xFF90CAF9);
  static const Color textMuted = Color(0xFF546E7A);

  // Sensor status colors
  static const Color good = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color danger = Color(0xFFFF1744);
  static const Color neutral = Color(0xFF40C4FF);

  // Chart colors
  static const Color chartPH = Color(0xFF7C4DFF);
  static const Color chartTurbidity = Color(0xFF00BFA5);
  static const Color chartTemp = Color(0xFFFF6D00);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1C2536)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
