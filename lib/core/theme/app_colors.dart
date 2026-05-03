import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF00D9A6);       // Electric mint — income, positive
  static const Color primaryDark = Color(0xFF00A882);
  static const Color secondary = Color(0xFF7C6FFF);     // Soft violet — accent, goals
  static const Color secondaryDark = Color(0xFF5A4FCC);

  // Semantic
  static const Color expense = Color(0xFFFF6B6B);       // Coral — expenses, danger
  static const Color expenseMuted = Color(0x33FF6B6B);
  static const Color income = Color(0xFF00D9A6);
  static const Color incomeMuted = Color(0x3300D9A6);
  static const Color warning = Color(0xFFFFB347);       // Amber — budget near-limit
  static const Color warningMuted = Color(0x33FFB347);

  // Backgrounds (dark financial aesthetic)
  static const Color background = Color(0xFF0D0F1C);
  static const Color surface = Color(0xFF161829);
  static const Color surfaceElevated = Color(0xFF1E2035);
  static const Color cardBorder = Color(0xFF252740);

  // Text
  static const Color textPrimary = Color(0xFFEEEFF5);
  static const Color textSecondary = Color(0xFF8B8FA8);
  static const Color textMuted = Color(0xFF4A4E6B);

  // Category colors (7 distinct, consistent across the app)
  static const Color catFood = Color(0xFFFF8C69);
  static const Color catTransport = Color(0xFF64B5F6);
  static const Color catShopping = Color(0xFFBA68C8);
  static const Color catEntertainment = Color(0xFFFFD54F);
  static const Color catHealth = Color(0xFF81C784);
  static const Color catBills = Color(0xFF4DD0E1);
  static const Color catOther = Color(0xFF90A4AE);
  static const Color catIncome = Color(0xFF00D9A6);
  static const Color catSavings = Color(0xFF7C6FFF);

  static Color forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining': return catFood;
      case 'transport': return catTransport;
      case 'shopping': return catShopping;
      case 'entertainment': return catEntertainment;
      case 'health': return catHealth;
      case 'bills & utilities': return catBills;
      case 'income': return catIncome;
      case 'savings': return catSavings;
      default: return catOther;
    }
  }
}
