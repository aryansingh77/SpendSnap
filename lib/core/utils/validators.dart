import 'package:flutter/services.dart';

class Validators {
  Validators._();

  static final _decimalRegex = RegExp(r'^\d+\.?\d{0,2}$');

  static TextInputFormatter get decimalFormatter =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty) return newValue;
        if (_decimalRegex.hasMatch(text)) return newValue;
        return oldValue;
      });

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than 0';
    if (parsed > 99999999) return 'Amount too large';
    return null;
  }

  static String? title(String? value, {int maxLength = 50}) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.trim().length > maxLength) return 'Too long (max $maxLength chars)';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }
}
