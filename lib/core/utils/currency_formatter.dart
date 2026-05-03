import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currency,
    decimalDigits: 0,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: AppConstants.currency,
    decimalDigits: 1,
  );

  static String format(double amount) => _formatter.format(amount.abs());

  static String compact(double amount) {
    if (amount.abs() < 1000) return format(amount);
    return _compactFormatter.format(amount.abs());
  }

  static String signed(double amount) {
    final formatted = format(amount);
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}
