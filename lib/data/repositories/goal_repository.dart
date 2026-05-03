import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';

class GoalRepository {
  GoalRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('goals');

  Stream<List<GoalModel>> watchGoals(String uid) {
    return _col(uid)
        .orderBy('deadline')
        .snapshots()
        .map((s) => s.docs.map((d) => GoalModel.fromFirestore(d)).toList());
  }

  Future<void> addGoal(GoalModel goal) =>
      _col(goal.userId).doc(goal.id).set(goal.toFirestore());

  Future<void> updateGoal(GoalModel goal) =>
      _col(goal.userId).doc(goal.id).update(goal.toFirestore());

  Future<void> deleteGoal(String uid, String goalId) =>
      _col(uid).doc(goalId).delete();

  Future<void> addFunds(String uid, String goalId, double amount) async {
    final doc = await _col(uid).doc(goalId).get();
    final goal = GoalModel.fromFirestore(doc);
    final updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
    );
    await _col(uid).doc(goalId).update({'currentAmount': updated.currentAmount});
  }
}
