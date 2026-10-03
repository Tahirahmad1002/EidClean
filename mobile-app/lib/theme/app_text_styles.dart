import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Inter-based type scale. Mirrors the web typography.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Headings
  static TextStyle get display => _inter(
      size: 32,
      weight: FontWeight.w700,
      color: AppColors.text,
      height: 1.2,
      letterSpacing: -0.8);
  static TextStyle get h1 => _inter(
      size: 28,
      weight: FontWeight.w700,
      color: AppColors.text,
      height: 1.25,
      letterSpacing: -0.6);
  static TextStyle get h2 => _inter(
      size: 22,
      weight: FontWeight.w700,
      color: AppColors.text,
      height: 1.3,
      letterSpacing: -0.3);
  static TextStyle get h3 => _inter(
      size: 18,
      weight: FontWeight.w600,
      color: AppColors.text,
      height: 1.35,
      letterSpacing: -0.2);

  // Titles
  static TextStyle get titleLarge => _inter(
      size: 16, weight: FontWeight.w600, color: AppColors.text, height: 1.4);
  static TextStyle get titleMedium => _inter(
      size: 14, weight: FontWeight.w600, color: AppColors.text, height: 1.4);

  // Body
  static TextStyle get bodyLarge => _inter(
      size: 16, weight: FontWeight.w400, color: AppColors.text, height: 1.5);
  static TextStyle get body => _inter(
      size: 14, weight: FontWeight.w400, color: AppColors.text, height: 1.5);
  static TextStyle get bodyMuted => _inter(
      size: 14,
      weight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.5);
  static TextStyle get bodySmall => _inter(
      size: 13,
      weight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.45);

  // Labels and captions
  static TextStyle get label => _inter(
      size: 14, weight: FontWeight.w500, color: AppColors.text, height: 1.4);
  static TextStyle get labelSmall => _inter(
      size: 12,
      weight: FontWeight.w500,
      color: AppColors.textMuted,
      height: 1.4);
  static TextStyle get caption => _inter(
      size: 12,
      weight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.4);
  static TextStyle get overline => _inter(
      size: 11,
      weight: FontWeight.w600,
      color: AppColors.textMuted,
      height: 1.4,
      letterSpacing: 0.8);

  // Numbers (stat values)
  static TextStyle get stat => _inter(
      size: 28,
      weight: FontWeight.w700,
      color: AppColors.text,
      height: 1.1,
      letterSpacing: -0.5);

  // Buttons (no color: the button theme supplies foreground color)
  static TextStyle get button => _inter(
      size: 15, weight: FontWeight.w600, height: 1.2, letterSpacing: -0.1);

  /// Plugged into ThemeData.textTheme so Text() widgets inherit Inter.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: h1,
        displaySmall: h2,
        headlineLarge: h1,
        headlineMedium: h2,
        headlineSmall: h3,
        titleLarge: h3,
        titleMedium: titleLarge,
        titleSmall: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: bodySmall,
        labelLarge: label,
        labelMedium: labelSmall,
        labelSmall: overline,
      );
}
