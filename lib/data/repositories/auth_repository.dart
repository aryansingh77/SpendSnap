import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserProfileModel> signUp({
    required String email,
    required String password,
    required String name,
    double monthlyIncome = 0.0,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    final profile = UserProfileModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      monthlyIncome: monthlyIncome,
    );
    await _db
        .collection('users')
        .doc(cred.user!.uid)
        .set(profile.toFirestore());
    return profile;
  }

  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db
        .collection('users')
        .doc(cred.user!.uid)
        .get();

    if (!doc.exists) {
      final profile = UserProfileModel(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? 'User',
        email: email,
      );
      await _db.collection('users').doc(cred.user!.uid).set(profile.toFirestore());
      return profile;
    }
    return UserProfileModel.fromFirestore(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<UserProfileModel?> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  Future<void> updateProfile(UserProfileModel profile) =>
      _db.collection('users').doc(profile.uid).update(profile.toFirestore());
}
