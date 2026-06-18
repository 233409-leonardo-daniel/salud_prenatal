import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD22E7E); // Pink/magenta accent from mockups
  static const Color primaryLight = Color(0xFFFFF0F6); // Soft pink background
  static const Color secondary = Color(0xFF9C27B0);
  
  static const Color background = Color(0xFFF9F9FB); // Off-white background
  static const Color cardBackground = Colors.white;

  // Risk levels
  static const Color riskHighBg = Color(0xFFFFEBEA);
  static const Color riskHighText = Color(0xFFD32F2F);
  
  static const Color riskMediumBg = Color(0xFFFFF4E5);
  static const Color riskMediumText = Color(0xFFE65100);
  
  static const Color riskLowBg = Color(0xFFE0F2F1);
  static const Color riskLowText = Color(0xFF00796B);

  static const Color textDark = Color(0xFF1A1A1E);
  static const Color textMuted = Color(0xFF757579);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        background: AppColors.background,
        surface: AppColors.cardBackground,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
  }
}
