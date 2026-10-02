// 📁 lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryBg = Color(0xFFECFDF5);
  static const Color background = Color(0xFFF8FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827); 
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);
}

// Use static methods instead of constants for TextStyle
class AppTheme {
  static const double borderRadius = 16;
  static const double borderRadiusSmall = 12;
  static const double borderRadiusLarge = 24;
  
  static const EdgeInsets paddingPage = EdgeInsets.all(20);
  static const EdgeInsets paddingCard = EdgeInsets.all(16);
  static const EdgeInsets paddingSmall = EdgeInsets.all(12);
  
  // ✅ Use getters instead of constants for TextStyle
  static TextStyle get heading {
    return const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle get subheading {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );
  }
  
  static TextStyle get body {
    return const TextStyle(
      fontSize: 13,
      color: AppColors.textSecondary,
    );
  }
  
  static TextStyle get bodyBold {
    return const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle get caption {
    return const TextStyle(
      fontSize: 11,
      color: AppColors.textLight,
    );
  }
  
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  static BoxDecoration get cardDecorationWithBorder {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.border),
    );
  }
}