import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note = '',
    this.isRecurring = false,
    this.recurringInterval,
  });

  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String note;
  final bool isRecurring;
  final String? recurringInterval;

  bool get isExpense => type == TransactionType.expense;

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'amount': amount,
    'type': type.name,
    'category': category,
    'date': Timestamp.fromDate(date),
    'note': note,
    'isRecurring': isRecurring,
    'recurringInterval': recurringInterval,
  };

  factory TransactionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      type: TransactionType.values.byName(data['type'] as String),
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String? ?? '',
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringInterval: data['recurringInterval'] as String?,
    );
  }

  TransactionModel copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? note,
    bool? isRecurring,
    String? recurringInterval,
  }) =>
      TransactionModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        date: date ?? this.date,
        note: note ?? this.note,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringInterval: recurringInterval ?? this.recurringInterval,
      );

  @override
  List<Object?> get props =>
      [id, userId, title, amount, type, category, date, note, isRecurring, recurringInterval];
}
