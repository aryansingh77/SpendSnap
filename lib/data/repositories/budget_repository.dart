import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('budgets');

  // Uses a single-field index (year only) and filters month client-side to
  // avoid requiring a composite Firestore index for the compound query.
  Stream<List<BudgetModel>> watchBudgetsForMonth(
      String uid, int month, int year) {
    return _col(uid)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((s) => s.docs
            .map((d) => BudgetModel.fromFirestore(d))
            .where((b) => b.month == month)
            .toList());
  }

  Future<List<BudgetModel>> fetchForMonth(
      String uid, int month, int year) async {
    final snap = await _col(uid)
        .where('year', isEqualTo: year)
        .get();
    return snap.docs
        .map((d) => BudgetModel.fromFirestore(d))
        .where((b) => b.month == month)
        .toList();
  }

  Future<void> addBudget(BudgetModel budget) =>
      _col(budget.userId).doc(budget.id).set(budget.toFirestore());

  Future<void> updateBudget(BudgetModel budget) =>
      _col(budget.userId).doc(budget.id).update(budget.toFirestore());

  Future<void> deleteBudget(String uid, String budgetId) =>
      _col(uid).doc(budgetId).delete();
}
