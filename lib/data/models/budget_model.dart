import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
    this.spentAmount = 0.0,
  });

  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final int month;
  final int year;
  final double spentAmount;

  double get remainingAmount => limitAmount - spentAmount;
  double get usagePercent => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spentAmount > limitAmount;
  bool get isNearLimit => usagePercent >= 0.8 && !isOverBudget;

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'category': category,
    'limitAmount': limitAmount,
    'month': month,
    'year': year,
  };

  factory BudgetModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BudgetModel(
      id: doc.id,
      userId: data['userId'] as String,
      category: data['category'] as String,
      limitAmount: (data['limitAmount'] as num).toDouble(),
      month: data['month'] as int,
      year: data['year'] as int,
    );
  }

  BudgetModel withSpent(double spent) => BudgetModel(
    id: id,
    userId: userId,
    category: category,
    limitAmount: limitAmount,
    month: month,
    year: year,
    spentAmount: spent,
  );

  BudgetModel copyWith({
    String? category,
    double? limitAmount,
    int? month,
    int? year,
    double? spentAmount,
  }) =>
      BudgetModel(
        id: id,
        userId: userId,
        category: category ?? this.category,
        limitAmount: limitAmount ?? this.limitAmount,
        month: month ?? this.month,
        year: year ?? this.year,
        spentAmount: spentAmount ?? this.spentAmount,
      );

  @override
  List<Object?> get props => [id, userId, category, limitAmount, month, year, spentAmount];
}
