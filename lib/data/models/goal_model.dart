import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GoalModel extends Equatable {
  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.colorHex,
    this.note = '',
  });

  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String colorHex;
  final String note;

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  int get daysLeft => deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => daysLeft < 0 && !isCompleted;

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': Timestamp.fromDate(deadline),
    'colorHex': colorHex,
    'note': note,
  };

  factory GoalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GoalModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num).toDouble(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      colorHex: data['colorHex'] as String,
      note: data['note'] as String? ?? '',
    );
  }

  GoalModel copyWith({
    double? currentAmount,
    String? title,
    double? targetAmount,
    DateTime? deadline,
    String? colorHex,
    String? note,
  }) =>
      GoalModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        colorHex: colorHex ?? this.colorHex,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, targetAmount, currentAmount, deadline, colorHex, note];
}
