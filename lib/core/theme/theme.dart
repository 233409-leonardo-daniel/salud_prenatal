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
  static Color get primaryLight => isDarkMode ? _primaryLightDark : _primaryLightLight; // Soft pink background -> dark burgundy
  static const Color secondary = Color(0xFF9C27B0);

  static Color get background => isDarkMode ? _backgroundDark : _backgroundLight; // Off-white background -> dark surface
  static Color get cardBackground => isDarkMode ? _cardBackgroundDark : _cardBackgroundLight; // White -> dark card grey

  // Risk levels
  static Color get riskHighBg => isDarkMode ? const Color(0xFF421C1A) : const Color(0xFFFFEBEA);
  static Color get riskHighText => isDarkMode ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);

  static Color get riskMediumBg => isDarkMode ? const Color(0xFF422E1A) : const Color(0xFFFFF4E5);
  static Color get riskMediumText => isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFE65100);

  static Color get riskLowBg => isDarkMode ? const Color(0xFF1A3835) : const Color(0xFFE0F2F1);
  static Color get riskLowText => isDarkMode ? const Color(0xFF80CBC4) : const Color(0xFF00796B);

  static Color get textDark => isDarkMode ? _textDarkDark : _textDarkLight; // Dark grey text -> soft white text
  static Color get textMuted => isDarkMode ? _textMutedDark : _textMutedLight; // Grey text -> light grey text

  // --- Literales fijos por variante ---
  //
  // IMPORTANTE: `AppTheme.lightTheme`/`darkTheme` (abajo) NO deben construirse
  // usando los getters de arriba (`background`, `cardBackground`, etc.),
  // porque esos getters dependen de `isDarkMode`, y `isDarkMode` todavía no
  // se ha actualizado cuando `MyApp.build()` evalúa `theme`/`darkTheme` por
  // primera vez (eso ocurre más abajo en el árbol, dentro del `builder` de
  // MaterialApp). Si `AppTheme.darkTheme` llamara a `AppColors.background`
  // en ese momento, "el tema oscuro" quedaría con el color CLARO grabado
  // para siempre (hasta que la app se reconstruya desde cero), rompiendo
  // todo lo que dependa de `Theme.of(context)` en vez de leer `AppColors`
  // directamente: menús de dropdown, DatePicker, diálogos, etc.
  static const Color _backgroundLight = Color(0xFFF9F9FB);
  static const Color _backgroundDark = Color(0xFF121212);
  static const Color _cardBackgroundLight = Color(0xFFFFFFFF);
  static const Color _cardBackgroundDark = Color(0xFF1E1E1E);
  static const Color _primaryLightLight = Color(0xFFFFF0F6);
  static const Color _primaryLightDark = Color(0xFF351A25);
  static const Color _textDarkLight = Color(0xFF1A1A1E);
  static const Color _textDarkDark = Color(0xFFFAF6F8);
  static const Color _textMutedLight = Color(0xFF757579);
  static const Color _textMutedDark = Color(0xFF9E9EAE);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        background: AppColors._backgroundLight,
        surface: AppColors._cardBackgroundLight,
      ),
      scaffoldBackgroundColor: AppColors._backgroundLight,
      cardColor: AppColors._cardBackgroundLight,
      canvasColor: AppColors._cardBackgroundLight,
      dialogBackgroundColor: AppColors._cardBackgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors._backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors._textDarkLight),
        titleTextStyle: TextStyle(
          color: AppColors._textDarkLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors._cardBackgroundLight,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors._cardBackgroundLight,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors._cardBackgroundLight,
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
        labelStyle: TextStyle(color: AppColors._textMutedLight),
        hintStyle: TextStyle(color: AppColors._textMutedLight),
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
        background: AppColors._backgroundDark,
        surface: AppColors._cardBackgroundDark,
      ),
      scaffoldBackgroundColor: AppColors._backgroundDark,
      cardColor: AppColors._cardBackgroundDark,
      canvasColor: AppColors._cardBackgroundDark,
      dialogBackgroundColor: AppColors._cardBackgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors._backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors._textDarkDark),
        titleTextStyle: TextStyle(
          color: AppColors._textDarkDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors._cardBackgroundDark,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors._cardBackgroundDark,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors._cardBackgroundDark,
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
        labelStyle: TextStyle(color: AppColors._textMutedDark),
        hintStyle: TextStyle(color: AppColors._textMutedDark),
      ),
    );
  }
}
