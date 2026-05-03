import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
    // Big balance display: ₹1,23,456
    displayLarge: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -1.0,
    ),
    // Section headers
    headlineMedium: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    // Card titles
    titleLarge: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    // Body
    bodyLarge: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    // Tags, chips
    labelLarge: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.5,
    ),
  );
}
