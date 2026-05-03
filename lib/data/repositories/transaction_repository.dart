import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Stream<List<TransactionModel>> watchTransactions(String uid) {
    return _col(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TransactionModel.fromFirestore(d))
            .toList());
  }

  Future<List<TransactionModel>> fetchForMonth(
      String uid, int month, int year) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final snap = await _col(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList();
  }

  Future<void> addTransaction(TransactionModel txn) =>
      _col(txn.userId).doc(txn.id).set(txn.toFirestore());

  Future<void> updateTransaction(TransactionModel txn) =>
      _col(txn.userId).doc(txn.id).update(txn.toFirestore());

  Future<void> deleteTransaction(String uid, String txnId) =>
      _col(uid).doc(txnId).delete();

  /// Returns total spent per category for a given month.
  Future<Map<String, double>> spentPerCategory(
      String uid, int month, int year) async {
    final txns = await fetchForMonth(uid, month, year);
    final map = <String, double>{};
    for (final t in txns) {
      if (t.isExpense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }
}
