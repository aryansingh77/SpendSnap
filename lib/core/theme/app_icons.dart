import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static IconData forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':     return Icons.restaurant_rounded;
      case 'transport':         return Icons.directions_car_rounded;
      case 'shopping':          return Icons.shopping_bag_rounded;
      case 'entertainment':     return Icons.movie_rounded;
      case 'health':            return Icons.favorite_rounded;
      case 'bills & utilities': return Icons.receipt_rounded;
      case 'income':            return Icons.trending_up_rounded;
      case 'savings':           return Icons.savings_rounded;
      default:                  return Icons.category_rounded;
    }
  }
}
