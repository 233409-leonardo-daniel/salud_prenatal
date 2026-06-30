import 'package:flutter/material.dart';

class DynamicColor extends Color {
  final int lightValue;
  final int darkValue;

  const DynamicColor(this.lightValue, this.darkValue) : super(lightValue);

  @override
  int get value => AppColors.isDarkMode ? darkValue : lightValue;
}

class AppColors {
  static bool isDarkMode = false;

  static const Color primary = Color(0xFFD22E7E); // Pink/magenta accent from mockups
  static Color get primaryLight => isDarkMode ? const Color(0xFF351A25) : const Color(0xFFFFF0F6); // Soft pink background -> dark burgundy
  static const Color secondary = Color(0xFF9C27B0);
  
  static Color get background => isDarkMode ? const Color(0xFF121212) : const Color(0xFFF9F9FB); // Off-white background -> dark surface
  static Color get cardBackground => isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF); // White -> dark card grey

  // Risk levels
  static Color get riskHighBg => isDarkMode ? const Color(0xFF421C1A) : const Color(0xFFFFEBEA);
  static Color get riskHighText => isDarkMode ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);
  
  static Color get riskMediumBg => isDarkMode ? const Color(0xFF422E1A) : const Color(0xFFFFF4E5);
  static Color get riskMediumText => isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  
  static Color get riskLowBg => isDarkMode ? const Color(0xFF1A3835) : const Color(0xFFE0F2F1);
  static Color get riskLowText => isDarkMode ? const Color(0xFF80CBC4) : const Color(0xFF00796B);

  static Color get textDark => isDarkMode ? const Color(0xFFFAF6F8) : const Color(0xFF1A1A1E); // Dark grey text -> soft white text
  static Color get textMuted => isDarkMode ? const Color(0xFF9E9EAE) : const Color(0xFF757579); // Grey text -> light grey text
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
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
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
          padding: EdgeInsets.symmetric(vertical: 16),
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: AppColors.textMuted),
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        background: AppColors.background,
        surface: AppColors.cardBackground,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
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
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: AppColors.textMuted),
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
