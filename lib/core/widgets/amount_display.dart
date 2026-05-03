import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Displays a monetary amount with sign-aware coloring and optional animation.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    required this.isExpense,
    this.style,
    this.showSign = true,
    this.compact = false,
  });

  final double amount;
  final bool isExpense;
  final TextStyle? style;
  final bool showSign;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '-' : '+';
    final formatted = compact
        ? CurrencyFormatter.compact(amount)
        : CurrencyFormatter.format(amount);

    return Text(
      showSign ? '$sign$formatted' : formatted,
      style: (style ?? Theme.of(context).textTheme.titleMedium)
          ?.copyWith(color: color),
    );
  }
}
