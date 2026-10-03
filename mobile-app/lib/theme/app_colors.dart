import 'package:flutter/material.dart';

/// Single source of truth for colors. Mirrors admin-site/tailwind.config.js.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryBg = Color(0xFFECFDF5);

  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFFCCFBF1);

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFEF3C7);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);

  // Surfaces and text
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Neutral scale (Slate). Use these instead of Colors.grey.
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Gradients (use sparingly: splash and hero headers only)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // Legacy aliases: keep existing references compiling
  static const Color textPrimary = text;
  static const Color textSecondary = textMuted;
  static const Color textLight = slate400;
  static const Color warning = accent;
  static const Color error = danger;
  static const Color info = secondary;
  static const Color priorityHigh = danger;
  static const Color priorityMedium = accent;
  static const Color priorityLow = primary;
}
