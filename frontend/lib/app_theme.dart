import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A237E);
  static const Color redAlert = Color(0xFFD32F2F);
  static const Color yellowAlert = Color(0xFFF9A825);
  static const Color greenAlert = Color(0xFF388E3C);
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surface = Color(0xFF1C2230);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color buttonColor = Color(0xFF1565C0);
  static const Color confirmYes = Color(0xFF2E7D32);
  static const Color confirmNo = Color(0xFFC62828);
  static const Color cardBorder = Color(0xFF2C3550);
}

class AppTextStyles {
  static const TextStyle hindiHeading = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle hindiTitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle hindiBody = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle hindiButton = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle hindiSmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle hindiLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.2,
  );
}

class AppTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.redAlert,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.hindiHeading,
        bodyLarge: AppTextStyles.hindiBody,
        bodyMedium: AppTextStyles.hindiSmall,
        labelLarge: AppTextStyles.hindiButton,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonColor,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          textStyle: AppTextStyles.hindiButton,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: AppTextStyles.hindiTitle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextStyles.hindiBody,
        hintStyle: AppTextStyles.hindiSmall,
      ),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.buttonColor,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(double.infinity, 72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      textStyle: AppTextStyles.hindiButton,
    );
  }

  static ButtonStyle yesButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.confirmYes,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(double.infinity, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      textStyle: AppTextStyles.hindiButton,
    );
  }

  static ButtonStyle noButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.confirmNo,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(double.infinity, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      textStyle: AppTextStyles.hindiButton,
    );
  }

  static ButtonStyle selectionButtonStyle({bool selected = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: selected ? AppColors.primary : AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(0, 72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.cardBorder,
          width: selected ? 2 : 1,
        ),
      ),
      elevation: selected ? 4 : 1,
      textStyle: AppTextStyles.hindiTitle,
    );
  }
}
