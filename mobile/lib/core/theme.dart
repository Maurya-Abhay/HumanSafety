import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8A8A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color greyDark = Color(0xFF424242);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);
  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDarkLight = Color(0xFF212121);
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textLightDark = Color(0xFFFAFAFA);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.black),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textDarkLight),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.accentLight,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.bgDark,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLightDark),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textLightDark),
    ),
  );
}