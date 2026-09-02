import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBackground,
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.only(bottom: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
);
