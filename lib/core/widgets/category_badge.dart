import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Colored pill-shaped badge showing a category with its icon.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.compact = false});

  final String category;
  final bool compact;

  static IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'entertainment': return Icons.movie_rounded;
      case 'health': return Icons.favorite_rounded;
      case 'bills & utilities': return Icons.receipt_long_rounded;
      case 'income': return Icons.arrow_downward_rounded;
      case 'savings': return Icons.savings_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCategory(category);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(category), color: color, size: compact ? 12 : 14),
          const SizedBox(width: 5),
          Text(
            category,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
